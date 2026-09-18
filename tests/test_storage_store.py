"""Executed SQLite protocol: evidence, bindings, projections, history, and scope."""

from __future__ import annotations

import hashlib
import json
import logging
import sqlite3
from collections.abc import Iterator
from pathlib import Path
from typing import Any

import pytest
from conftest import (
    FINDINGS_SUMMARY_ROWS,
    FINDINGS_SUMMARY_SCOPE,
    report_with_findings,
    seed_findings_summary,
)
from storage_samples import (
    FAMILIES,
    PROJECTION_TABLES,
    RUN_BOUND,
    SECONDARY_PROJECTION_TABLES,
    encode,
    sample,
)

from traust_contracts.v1.storage import Binding, IngestError, Store, binding_id
from traust_contracts.v1.storage.sql import CONTRACT_VERSION, REVISION

TABLES = [
    "artifact_binding",
    "artifact_evidence",
    *sorted(set(PROJECTION_TABLES.values()) | set(SECONDARY_PROJECTION_TABLES.values())),
]


@pytest.fixture
def store() -> Iterator[Store]:
    conn = sqlite3.connect(":memory:")
    storage = Store(conn)
    storage.init()
    yield storage
    conn.close()


def run_binding(
    *,
    scope: str = "local",
    subject: str = "sci:inventory-item:42",
    run: str = "sci:scan-result:7",
    layer: str | None = None,
    supersedes: str | None = None,
) -> Binding:
    return Binding(scope, subject, run, layer, supersedes)


def binding_for(name: str) -> Binding:
    if name in RUN_BOUND:
        return run_binding()
    if name == "layer":
        return Binding(layer_id="ledger:layer:1")
    return Binding()


def assert_empty(store: Store) -> None:
    for name in TABLES:
        assert store.conn.execute(f"SELECT count(*) FROM {name}").fetchone()[0] == 0


def test_init_revision_and_dependency_shape(store: Store) -> None:
    conn = store.conn
    names = {row[0] for row in conn.execute("SELECT name FROM sqlite_master WHERE type='table'")}
    assert names == {*TABLES, "traust_storage_meta"}
    views = {row[0] for row in conn.execute("SELECT name FROM sqlite_master WHERE type='view'")}
    assert views == {"current_binding", "findings_summary"}
    assert conn.execute("PRAGMA foreign_keys").fetchone() == (1,)
    original = conn.execute("SELECT * FROM traust_storage_meta").fetchall()
    assert len(original) == 1 and original[0][:3] == (1, CONTRACT_VERSION, REVISION)
    store.init()
    assert conn.execute("SELECT * FROM traust_storage_meta").fetchall() == original
    conn.execute("UPDATE traust_storage_meta SET revision=?", (REVISION - 1,))
    conn.commit()
    with pytest.raises(IngestError, match=r"explicit migration"):
        store.init()


def test_binding_id_golden_vector_and_presence_encoding() -> None:
    digest = hashlib.sha256(b"").hexdigest()
    present = Binding(subject_id="sci:inventory-item:42")
    assert binding_id(digest, "triage", present) == (
        "90933ec74bd66618428c4def90f4af4cb9a2ab60bc9bd24a20b64814ca2dba56"
    )
    assert binding_id(digest, "triage", Binding()) != binding_id(
        digest, "triage", Binding(subject_id="")
    )
    with pytest.raises(IngestError, match="NUL"):
        binding_id(digest, "triage", Binding(subject_id="bad\x00id"))


@pytest.mark.parametrize("name", FAMILIES)
def test_all_artifacts_retain_exact_evidence_and_project(store: Store, name: str) -> None:
    payload, _ = sample(name)
    result = store.ingest(name, payload, binding_for(name))
    assert store.get_evidence(result.digest) == payload
    assert store.get(name, result.binding_id) == payload
    assert store.get_binding(result.binding_id).binding == binding_for(name)
    table = PROJECTION_TABLES[name]
    count = store.conn.execute(f"SELECT count(*) FROM {table}").fetchone()[0]
    # Fan-out families project one row per item in their sample.
    assert count == (2 if name in {"vuln-findings", "corpus-registry"} else 1)


def test_global_evidence_dedup_is_private_and_binding_scoped(store: Store) -> None:
    payload, _ = sample("adr-registry")
    first = store.ingest("adr-registry", payload, Binding(scope_id="a"))
    second = store.ingest("adr-registry", payload, Binding(scope_id="b"))
    retry = store.ingest("adr-registry", payload, Binding(scope_id="b"))
    assert first.digest == second.digest == retry.digest
    assert first.binding_id != second.binding_id == retry.binding_id
    assert not first.already_bound and not second.already_bound and retry.already_bound
    assert store.conn.execute("SELECT count(*) FROM artifact_evidence").fetchone() == (1,)
    assert store.conn.execute("SELECT count(*) FROM artifact_binding").fetchone() == (2,)


def test_typed_read_uses_binding_name_and_rechecks_evidence(store: Store) -> None:
    payload, _ = sample("vuln-findings")
    result = store.ingest("vuln-findings", payload, run_binding())
    with pytest.raises(IngestError, match="type mismatch"):
        store.get("triage", result.binding_id)
    store.conn.execute(
        "UPDATE artifact_evidence SET payload=? WHERE digest=?", (payload + b" ", result.digest)
    )
    store.conn.commit()
    with pytest.raises(IngestError, match="digest mismatch"):
        store.get_evidence(result.digest)
    with pytest.raises(IngestError, match="not found"):
        store.get_evidence("0" * 64)


@pytest.mark.parametrize("name,missing", [("vuln-findings", "subject_id"), ("triage", "run_id")])
def test_run_profile_requires_explicit_context(store: Store, name: str, missing: str) -> None:
    payload, _ = sample(name)
    values: dict[str, Any] = {"subject_id": "subject", "run_id": "run"}
    values[missing] = None
    with pytest.raises(IngestError, match=missing):
        store.ingest(name, payload, Binding(**values))
    assert_empty(store)


def test_layer_profile_requires_layer_only(store: Store) -> None:
    payload, _ = sample("layer")
    with pytest.raises(IngestError, match="layer_id"):
        store.ingest("layer", payload)
    result = store.ingest("layer", payload, Binding(layer_id="ledger/layer:team/a"))
    assert store.get("layer", result.binding_id) == payload


def test_explicit_supersession_is_current_and_backfill_order_free(store: Store) -> None:
    initial, _ = sample("vuln-findings")
    context = run_binding(layer="ledger:layer:1")
    first = store.ingest("vuln-findings", initial, context)
    corrected = json.loads(initial)
    corrected["findings"][0]["title"] = "Corrected title"
    second = store.ingest(
        "vuln-findings",
        encode(corrected),
        run_binding(layer="ledger:layer:1", supersedes=first.binding_id),
    )
    assert store.conn.execute(
        "SELECT binding_id FROM current_binding WHERE artifact_name='vuln-findings'"
    ).fetchall() == [(second.binding_id,)]
    assert store.get("vuln-findings", first.binding_id) == initial
    assert store.get("vuln-findings", second.binding_id) == encode(corrected)


def test_supersession_rejects_missing_cross_context_and_branches(store: Store) -> None:
    payload, _ = sample("vuln-findings")
    first = store.ingest("vuln-findings", payload, run_binding())
    changed = json.loads(payload)
    changed["findings"][0]["title"] = "Corrected title one"
    with pytest.raises(IngestError, match="not found"):
        store.ingest("vuln-findings", encode(changed), run_binding(supersedes="0" * 64))
    with pytest.raises(IngestError, match="context mismatch"):
        store.ingest(
            "vuln-findings",
            encode(changed),
            run_binding(scope="other", supersedes=first.binding_id),
        )
    successor = store.ingest(
        "vuln-findings", encode(changed), run_binding(supersedes=first.binding_id)
    )
    changed["findings"][0]["title"] = "Corrected title two"
    with pytest.raises(IngestError):
        store.ingest("vuln-findings", encode(changed), run_binding(supersedes=first.binding_id))
    assert store.conn.execute("SELECT count(*) FROM current_binding").fetchone() == (1,)
    assert store.get_binding(successor.binding_id).binding.supersedes_binding_id == first.binding_id


def test_findings_summary_joins_same_run_and_optional_layer_repo(store: Store) -> None:
    """The SQLite half of the cross-dialect parity pair.

    Fixture and expectation are shared with
    `test_storage_postgres.py::test_postgres_findings_summary_uses_json_scope_and_same_run`
    so the two views cannot drift behind separately-authored setups.
    """
    seed_findings_summary(store)
    assert store.query_findings_summary([FINDINGS_SUMMARY_SCOPE]) == FINDINGS_SUMMARY_ROWS
    assert store.query_findings_summary(["other"]) == []


def test_projection_failure_rolls_back_evidence_and_binding(store: Store) -> None:
    payload, _ = sample("vuln-findings")
    second = json.loads(payload)["findings"][1]["id"]
    store.conn.execute(
        "CREATE TRIGGER fail_second BEFORE INSERT ON finding "
        f"WHEN NEW.finding_id = '{second}' BEGIN SELECT RAISE(ABORT, 'blocked'); END"
    )
    with pytest.raises(IngestError, match="SQLITE"):
        store.ingest("vuln-findings", payload, run_binding())
    assert_empty(store)


def test_caller_transaction_and_error_logs_preserve_evidence_boundary(
    store: Store, caplog: pytest.LogCaptureFixture
) -> None:
    payload, _ = sample("vuln-findings")
    store.conn.execute("BEGIN")
    with pytest.raises(IngestError, match="caller transaction is untouched"):
        store.ingest("vuln-findings", payload, run_binding())
    store.conn.execute("ROLLBACK")
    marker = b'PRIVATE_ROW_CONTENT:{"broken"'
    try:
        store.ingest("vuln-findings", marker, run_binding())
    except IngestError as error:
        assert error.payload is marker
        logging.getLogger(__name__).exception("save failed")
    else:
        pytest.fail("invalid evidence was accepted")
    assert "PRIVATE_ROW_CONTENT" not in caplog.text


def test_fixture_remains_exact(store: Store) -> None:
    payload = (
        Path(__file__).parent / "fixtures/storage/vuln-findings-populated.test.json"
    ).read_bytes()
    result = store.ingest("vuln-findings", payload, run_binding())
    assert store.get_evidence(result.digest) == payload
    assert store.conn.execute("SELECT count(*) FROM finding").fetchone() == (5,)


def test_patch_evidence_projects_into_a_queryable_column(store: Store) -> None:
    """Exact bytes were always kept in artifact_evidence; the column was not."""
    item = {
        "kind": "mutation",
        "outcome": "proves",
        "base_observation": "mutant 7 survives at oauth.go:212",
        "patched_observation": "19 caught, 0 uncaught",
        "tool": "mewt 4.0.0",
        "deterministic_steps": "ran",
    }
    for name in ("remediation", "verification"):
        payload, _ = sample(name)
        document = json.loads(payload)
        document["evidence"] = [item]
        result = store.ingest(name, encode(document), binding_for(name))

        row = store.conn.execute(
            f"SELECT evidence FROM {PROJECTION_TABLES[name]} WHERE binding_id = ?",
            (result.binding_id,),
        ).fetchone()
        assert row is not None, f"{name} row missing"
        assert json.loads(row[0]) == [item], f"{name} evidence not projected"


def test_absent_patch_evidence_projects_as_null(store: Store) -> None:
    """Optional means optional: a report without evidence still projects."""
    for name in ("remediation", "verification"):
        payload, _ = sample(name)
        assert "evidence" not in json.loads(payload)
        result = store.ingest(name, payload, binding_for(name))
        row = store.conn.execute(
            f"SELECT evidence FROM {PROJECTION_TABLES[name]} WHERE binding_id = ?",
            (result.binding_id,),
        ).fetchone()
        assert row[0] is None


def test_report_findings_project_disposition_and_fingerprint(store: Store) -> None:
    """GAP A/B: what was locked in report.findings is now queryable.

    The blob is unchanged -- this is an index over it, not a replacement.
    """
    result = store.ingest("report", report_with_findings(), binding_for("report"))

    rows = store.conn.execute(
        "SELECT finding_id, fingerprint, validity, resolution, assurance, "
        "conflict, fp_overridden, fp_reassertion_blocked, refuted_awaiting_signoff, "
        "severity_override, validation_status "
        "FROM report_finding WHERE binding_id = ? ORDER BY finding_id",
        (result.binding_id,),
    ).fetchall()
    assert len(rows) == 2, "every finding projects, disposed or not"

    disposed, bare = rows
    assert disposed[:5] == (
        "FIND-001",
        "a" * 64,
        "confirmed",
        "fix_in_progress",
        "execution_proven",
    )
    # The two-person-rule flags survive the projection.
    assert (disposed[5], disposed[6], disposed[7], disposed[8]) == (0, 1, 1, 0)
    assert json.loads(disposed[9])["severity"] == "critical"
    assert disposed[10] == "confirmed"

    # A finding with no disposition still projects, carrying identity only.
    assert bare[0] == "FIND-002"
    assert all(value is None for value in bare[1:])


def test_report_blob_is_unchanged_by_the_new_projection(store: Store) -> None:
    """The index must not become a second source of truth."""
    payload = report_with_findings()
    result = store.ingest("report", payload, binding_for("report"))
    assert store.get_evidence(result.digest) == payload
    assert store.get("report", result.binding_id) == payload
    stored = store.conn.execute(
        "SELECT findings FROM report WHERE binding_id = ?", (result.binding_id,)
    ).fetchone()[0]
    assert json.loads(stored) == json.loads(payload)["findings"]


def test_absent_disposition_flag_is_null_not_false(store: Store) -> None:
    """ "Nobody overrode this FP" and "no record either way" differ, and the
    two-person rule depends on the difference."""
    document = json.loads(report_with_findings())
    del document["findings"][0]["disposition"]["fp_overridden"]
    result = store.ingest("report", encode(document), binding_for("report"))
    value = store.conn.execute(
        "SELECT fp_overridden FROM report_finding WHERE binding_id = ? AND finding_id = ?",
        (result.binding_id, "FIND-001"),
    ).fetchone()[0]
    assert value is None


def test_subject_ownership_projects_the_denominator_columns(store: Store) -> None:
    """GAP C: ownership had no contract home, so "X% of our repos" was
    uncomputable from storage/v1. These are the columns every cut divides by."""
    payload, _ = sample("corpus-registry")
    result = store.ingest("corpus-registry", payload, Binding())
    rows = store.conn.execute(
        "SELECT subject_id, tree, ownership, business_unit, product, ref_kind, "
        "is_branch_audit FROM subject_ownership WHERE binding_id = ? ORDER BY subject_id",
        (result.binding_id,),
    ).fetchall()
    assert rows == [
        (
            "findings/example/repo",
            "findings",
            "owned",
            "Platform Group",
            "example-product",
            None,
            0,
        ),
        (
            "other/example/repo@release-1.0",
            "other-findings",
            "external-bu",
            "Other Unit",
            None,
            "branch",
            1,
        ),
    ]


def test_ownership_joins_findings_to_a_denominator(store: Store) -> None:
    """The point of the projection: a finding can be cut by who owns it.

    Before this table the join had no left-hand side at all -- storage/v1
    knew a finding's subject_id and nothing about that subject.
    """
    store.ingest("corpus-registry", sample("corpus-registry")[0], Binding())
    store.ingest(
        "report",
        report_with_findings(),
        Binding(subject_id="findings/example/repo", run_id="run:1"),
    )
    rows = store.conn.execute(
        "SELECT o.ownership, o.business_unit, count(*) "
        "FROM report_finding f "
        "JOIN artifact_binding b ON b.binding_id = f.binding_id "
        "JOIN subject_ownership o ON o.subject_id = b.subject_id "
        "GROUP BY o.ownership, o.business_unit"
    ).fetchall()
    assert rows == [("owned", "Platform Group", 2)]


def test_branch_re_audits_are_separable_from_head(store: Store) -> None:
    """is_branch_audit is the column a denominator must exclude on.

    A large share of audits are branch re-audits of the same code, so a
    coverage number that counts them is overstated. Without this column the
    exclusion cannot be expressed at all.
    """
    result = store.ingest("corpus-registry", sample("corpus-registry")[0], Binding())
    head = store.conn.execute(
        "SELECT count(*) FROM subject_ownership WHERE binding_id = ? AND is_branch_audit = 0",
        (result.binding_id,),
    ).fetchone()[0]
    total = store.conn.execute(
        "SELECT count(*) FROM subject_ownership WHERE binding_id = ?", (result.binding_id,)
    ).fetchone()[0]
    assert (head, total) == (1, 2), "the sample carries one HEAD audit and one branch re-audit"


def test_absent_is_branch_audit_is_null_not_false(store: Store) -> None:
    """ "Not a branch audit" and "unknown" must not collapse: the second is a
    registry gap and should be visible as one."""
    document = json.loads(sample("corpus-registry")[0])
    del document["subjects"][0]["is_branch_audit"]
    result = store.ingest("corpus-registry", encode(document), Binding())
    value = store.conn.execute(
        "SELECT is_branch_audit FROM subject_ownership WHERE binding_id = ? AND subject_id = ?",
        (result.binding_id, "findings/example/repo"),
    ).fetchone()[0]
    assert value is None
