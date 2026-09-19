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
    assert views == {
        "census_exposure",
        "census_population",
        "current_binding",
        "current_finding",
        "distinct_exposure",
        "ownership_current",
        "findings_summary",
        "hardening_findings",
        "open_findings",
        "operator_privilege",
        "report_current",
        "threat_current",
        "threat_exposure",
    }
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
    assert count == (
        2 if name in {"vuln-findings", "corpus-registry", "threat-register"} else 1
    )


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


def _audit_and_findings_current(subject: str = "repo/a") -> tuple[bytes, bytes]:
    """The same finding set, restated as a plain audit and a disposition-aware
    findings-current report. Neither supersedes the other."""
    audit = json.loads(report_with_findings())
    for finding in audit["findings"]:
        finding.pop("disposition", None)
    current = json.loads(report_with_findings())
    current["disposition_summary"] = {
        "layer_ref": "repo-findings-layer.json",
        "generated_at": "2026-01-02T00:00:00Z",
        "by_resolution": {
            "open": 2,
            "fix_in_progress": 0,
            "resolved": 0,
            "partially_resolved": 0,
            "risk_accepted": 0,
            "regression_introduced": 0,
        },
        "by_validity": {
            "confirmed": 1,
            "corrected": 0,
            "false_positive": 0,
            "not_verified": 1,
        },
    }
    return encode(audit), encode(current)


def test_report_current_collapses_restatements_of_one_subject(store: Store) -> None:
    """GAP D: both restatements are legitimately current, so counting
    report_finding directly counts every finding once per restatement."""
    audit, current = _audit_and_findings_current()
    store.ingest("report", audit, Binding(subject_id="repo/a", run_id="run:audit"))
    store.ingest("report", current, Binding(subject_id="repo/a", run_id="run:current"))

    naive = store.conn.execute("SELECT count(*) FROM report_finding").fetchone()[0]
    distinct = store.conn.execute(
        "SELECT count(DISTINCT finding_id) FROM report_finding"
    ).fetchone()[0]
    assert (naive, distinct) == (4, 2), "the double count this view exists to fix"

    rows = store.conn.execute("SELECT subject_id, disposition_aware FROM report_current").fetchall()
    assert rows == [("repo/a", 1)], "exactly one, and the disposition-aware one"

    counted = store.conn.execute(
        "SELECT count(*) FROM report_finding f JOIN report_current c ON c.binding_id = f.binding_id"
    ).fetchone()[0]
    assert counted == 2, "each finding counted once"


def test_report_current_prefers_disposition_awareness_over_recency(store: Store) -> None:
    """Order of ingest must not decide the answer -- the layer does."""
    audit, current = _audit_and_findings_current()
    store.ingest("report", current, Binding(subject_id="repo/a", run_id="run:current"))
    store.ingest("report", audit, Binding(subject_id="repo/a", run_id="run:audit"))
    assert store.conn.execute("SELECT disposition_aware FROM report_current").fetchall() == [(1,)]


def test_report_current_is_deterministic_among_equals(store: Store) -> None:
    """Two reports of the same layer for one subject still yield ONE row."""
    first = json.loads(report_with_findings())
    first["title"] = "Audit one"
    second = json.loads(report_with_findings())
    second["title"] = "Audit two"
    for payload, run in ((first, "run:1"), (second, "run:2")):
        store.ingest("report", encode(payload), Binding(subject_id="repo/a", run_id=run))
    assert store.conn.execute("SELECT count(*) FROM report_current").fetchall() == [(1,)]

    # Force the recency signal to a tie. Without a tie-break the view would
    # return both rows, and "the current report" would depend on nothing.
    store.conn.execute("UPDATE artifact_binding SET bound_at = '2026-01-01T00:00:00Z'")
    assert store.conn.execute("SELECT count(*) FROM report_current").fetchall() == [(1,)]


def test_report_current_keeps_distinct_subjects_apart(store: Store) -> None:
    """Collapsing restatements must not collapse different repos."""
    audit, current = _audit_and_findings_current()
    for subject in ("repo/a", "repo/b"):
        store.ingest("report", audit, Binding(subject_id=subject, run_id=f"{subject}:audit"))
        store.ingest("report", current, Binding(subject_id=subject, run_id=f"{subject}:cur"))
    assert store.conn.execute(
        "SELECT subject_id FROM report_current ORDER BY subject_id"
    ).fetchall() == [("repo/a",), ("repo/b",)]


def _cloud_config_with_findings() -> bytes:
    """Shaped from REAL corpus findings, not invented.

    The first attempt guessed: provider="checkov" (it is an enum of clouds),
    status="FAILED" (it is confirmed|suppressed|needs_review), and omitted
    fact_ids / effective_severity / disposition.assurance, all required.
    Two findings on ONE resource differing only by check_id -- the case
    check_id exists to separate.
    """
    document = json.loads(sample("cloud-config-findings-current")[0])
    base = {
        "fact_ids": ["cca-d26590b3507a"],
        "framework": "bicep",
        "provider": "azure",
        "rationale": "r" * 30,
        "locations": [
            {
                "file_path": "/modules/rp-cosmos-account.bicep",
                "resource": "Microsoft.DocumentDB/databaseAccounts.cosmosDbAccount",
                "file_line_range": [8, 51],
            }
        ],
        "cwe": "CWE-284",
        "validation_status": "not_verified",
        "disposition": {
            "validity": "not_verified",
            "resolution": "open",
            "assurance": "claimed",
            "last_updated": "2026-07-29T06:10:00Z",
            "events": [],
        },
    }
    document["findings"] = [
        {
            **base,
            "id": "CCA-ARO-HCP-001",
            "check_id": "CKV_AZURE_101",
            "title": "Ensure that Azure Cosmos DB disables public network access",
            "severity": "high",
            "effective_severity": "high",
            "scanner_severity": "unrated",
            "status": "confirmed",
            "fingerprint": "b" * 64,
            "fingerprint_algo": "v3",
        },
        {
            **base,
            "id": "CCA-ARO-HCP-002",
            "check_id": "CKV_AZURE_99",
            "title": "Ensure that Cosmos DB accounts have restricted firewall rules",
            "severity": "low",
            "effective_severity": "low",
            "status": "needs_review",
        },
    ]
    return encode(document)


def test_cloud_config_findings_project_into_queryable_rows(store: Store) -> None:
    """91 repos carrying 2,592 findings were absent from every storage/v1
    query while present in findings.db, because this family projected one
    row and kept its findings in a JSON column."""
    payload = _cloud_config_with_findings()
    result = store.ingest("cloud-config-findings-current", payload, run_binding())

    rows = store.conn.execute(
        "SELECT finding_id, check_id, framework, provider, status, severity, "
        "fingerprint, validity, resolution, fp_overridden "
        "FROM cloud_config_finding WHERE binding_id = ? ORDER BY finding_id",
        (result.binding_id,),
    ).fetchall()
    assert len(rows) == 2, "every finding projects, disposed or not"

    first, second = rows
    assert first[:6] == (
        "CCA-ARO-HCP-001",
        "CKV_AZURE_101",
        "bicep",
        "azure",
        "confirmed",
        "high",
    )
    assert first[6] == "b" * 64
    assert first[7:10] == ("not_verified", "open", None)
    # check_id is what separates two findings on ONE resource.
    assert second[0] == "CCA-ARO-HCP-002" and second[1] == "CKV_AZURE_99"
    assert second[4] == "needs_review" and second[6] is None

    # The blob stays authoritative.
    assert store.get_evidence(result.digest) == payload


def test_cloud_config_findings_are_separable_by_check(store: Store) -> None:
    """Two findings on the same resource must not be indistinguishable."""
    result = store.ingest(
        "cloud-config-findings-current", _cloud_config_with_findings(), run_binding()
    )
    checks = store.conn.execute(
        "SELECT count(DISTINCT check_id) FROM cloud_config_finding WHERE binding_id = ?",
        (result.binding_id,),
    ).fetchone()[0]
    assert checks == 2


def _registry(subject: str, *, ownership: str = "owned", branch: bool = False) -> bytes:
    return encode(
        {
            "version": 1,
            "subjects": [
                {
                    "subject_id": subject,
                    "tree": "findings",
                    "ownership": ownership,
                    "business_unit": "Platform Group",
                    "is_branch_audit": branch,
                }
            ],
        }
    )


def _seed_dashboard(store: Store, *, ownership: str = "owned", branch: bool = False) -> None:
    """A code report and a policy report for one subject, plus its ownership."""
    subject = "findings/org/repo"
    store.ingest(
        "corpus-registry", _registry(subject, ownership=ownership, branch=branch), Binding()
    )
    store.ingest("report", report_with_findings(), Binding(subject_id=subject, run_id="r1"))
    store.ingest(
        "cloud-config-findings-current",
        _cloud_config_with_findings(),
        Binding(subject_id=subject, run_id="r1"),
    )


def test_the_spine_unions_code_and_policy_findings(store: Store) -> None:
    """A dashboard reading only report_finding omits every policy finding."""
    _seed_dashboard(store)
    families = dict(
        store.conn.execute("SELECT family, count(*) FROM current_finding GROUP BY family")
    )
    assert families == {"code": 2, "policy": 2}


def test_the_spine_carries_ownership(store: Store) -> None:
    """Ownership is the denominator and lives in neither finding table."""
    _seed_dashboard(store)
    rows = set(store.conn.execute("SELECT DISTINCT ownership, business_unit FROM current_finding"))
    assert rows == {("owned", "Platform Group")}


def test_open_findings_excludes_hardening_and_false_positives(store: Store) -> None:
    _seed_dashboard(store)
    store.conn.execute("UPDATE report_finding SET validity='hardening' WHERE finding_id='FIND-001'")
    store.conn.execute(
        "UPDATE report_finding SET validity='false_positive' WHERE finding_id='FIND-002'"
    )
    store.conn.commit()
    ids = {r[3] for r in store.query_open_findings(["local"])}
    assert "FIND-001" not in ids and "FIND-002" not in ids


def test_open_findings_keeps_partial_fixes_and_regressions(store: Store) -> None:
    """Open is anything not AFFIRMATIVELY closed -- these are still exposure."""
    _seed_dashboard(store)
    for resolution in ("fix_in_progress", "partially_resolved", "regression_introduced"):
        store.conn.execute(
            "UPDATE report_finding SET resolution=? WHERE finding_id='FIND-001'", (resolution,)
        )
        store.conn.commit()
        ids = {r[3] for r in store.query_open_findings(["local"])}
        assert "FIND-001" in ids, resolution
    store.conn.execute(
        "UPDATE report_finding SET resolution='resolved' WHERE finding_id='FIND-001'"
    )
    store.conn.commit()
    assert "FIND-001" not in {r[3] for r in store.query_open_findings(["local"])}


def test_hardening_is_separate_from_open(store: Store) -> None:
    _seed_dashboard(store)
    store.conn.execute("UPDATE report_finding SET validity='hardening' WHERE finding_id='FIND-001'")
    store.conn.commit()
    assert {r[3] for r in store.query_hardening_findings(["local"])} == {"FIND-001"}
    assert "FIND-001" not in {r[3] for r in store.query_open_findings(["local"])}


def test_distinct_exposure_excludes_unowned_and_branch_audits(store: Store) -> None:
    """Both filters carry meaning: upstream/external-bu are Lens 1 only, and
    branch re-audits of the same code overstate coverage."""
    _seed_dashboard(store)
    assert store.query_distinct_exposure(["local"]), "owned HEAD audit must appear"

    for kwargs in ({"ownership": "upstream"}, {"branch": True}):
        other = Store(sqlite3.connect(":memory:"))
        other.init()
        _seed_dashboard(other, **kwargs)
        assert other.query_distinct_exposure(["local"]) == [], kwargs


def test_census_exposure_classifies_every_finding_exactly_once(store: Store) -> None:
    """Exhaustive and mutually exclusive, or the census over- or under-counts.

    A consumer FILTERS this view instead of restating the disposition policy,
    so a finding that falls through every branch -- or matches two -- is a
    silent arithmetic error in every cut built on top of it.
    """
    _seed_dashboard(store)
    store.conn.execute("UPDATE report_finding SET validity='hardening' WHERE finding_id='FIND-001'")
    store.conn.execute(
        "UPDATE report_finding SET resolution='risk_accepted' WHERE finding_id='FIND-002'"
    )
    store.conn.commit()
    total = store.conn.execute("SELECT COUNT(*) FROM current_finding").fetchone()[0]
    rows = store.query_census_exposure(["local"])
    assert sum(row[8] for row in rows) == total
    assert {row[7] for row in rows} <= {"false_positive", "hardening", "closed", "open"}


def test_census_exposure_prefers_validity_over_resolution(store: Store) -> None:
    """A hardening item that is also resolved is hardening, not closed.

    Ordering matters: classify it as closed and posture debt vanishes from
    the backlog the moment someone marks it fixed on one subject.
    """
    _seed_dashboard(store)
    store.conn.execute(
        "UPDATE report_finding SET validity='hardening', resolution='resolved' "
        "WHERE finding_id='FIND-001'"
    )
    store.conn.commit()
    classes = {
        row[7]: row[8]
        for row in store.query_census_exposure(["local"])
        if row[5] == "code" and row[7] == "hardening"
    }
    assert classes.get("hardening") == 1


def test_census_population_counts_a_subject_with_no_findings(store: Store) -> None:
    """The denominator comes from ownership, not from findings.

    A subject that was audited clean is still coverage. Counting the
    denominator from findings drops it and overstates every percentage
    divided by it -- which is the specific way census numbers drifted.
    """
    _seed_dashboard(store)
    store.ingest(
        "corpus-registry",
        encode(
            {
                "version": 1,
                "subjects": [
                    {
                        "subject_id": "findings/org/repo",
                        "tree": "findings",
                        "ownership": "owned",
                        "business_unit": "Platform Group",
                        "is_branch_audit": False,
                    },
                    {
                        "subject_id": "findings/org/clean",
                        "tree": "findings",
                        "ownership": "owned",
                        "business_unit": "Platform Group",
                        "is_branch_audit": False,
                    },
                ],
            }
        ),
        Binding(),
    )
    rows = store.query_census_population(["local"])
    assert len(rows) == 1
    subjects, branch_reaudits, with_report = rows[0][4], rows[0][5], rows[0][6]
    assert (subjects, branch_reaudits, with_report) == (2, 0, 1)


def test_reimporting_the_registry_does_not_double_the_numbers(store: Store) -> None:
    """The shape that made every view wrong on the second import.

    corpus-registry restates the whole population and carries an `updated`
    timestamp, so each import is new content, a new digest and a new
    binding; subject_ownership keeps a row set per binding. Measured on the
    live corpus before ownership_current: one re-import took current_finding
    from 79,855 to 159,710 and the census population from 8,604 to 17,208.
    Invisible in the suite until now because the store was always fresh.
    """
    _seed_dashboard(store)

    def numbers() -> tuple[int, int, int]:
        findings = store.conn.execute("SELECT COUNT(*) FROM current_finding").fetchone()[0]
        population = store.conn.execute(
            "SELECT SUM(subjects) FROM census_population"
        ).fetchone()[0]
        exposure = store.conn.execute(
            "SELECT SUM(occurrences) FROM census_exposure"
        ).fetchone()[0]
        return findings, population, exposure

    before = numbers()
    assert before[0] and before[1] and before[2]

    # Byte-different content -- exactly what `updated` guarantees per import.
    store.ingest(
        "corpus-registry",
        encode(
            {
                "version": 1,
                "updated": "2026-09-19T00:00:00Z",
                "subjects": [
                    {
                        "subject_id": "findings/org/repo",
                        "tree": "findings",
                        "ownership": "owned",
                        "business_unit": "Platform Group",
                        "is_branch_audit": False,
                    }
                ],
            }
        ),
        Binding(),
    )
    assert store.conn.execute("SELECT COUNT(*) FROM subject_ownership").fetchone()[0] == 2, (
        "the raw table is expected to accumulate -- that is why the view exists"
    )
    assert numbers() == before


def test_ownership_current_takes_the_latest_declaration(store: Store) -> None:
    """A re-import is also how ownership CHANGES. Deduplicating must not
    freeze the first answer -- a repo moving business unit has to land."""
    _seed_dashboard(store)
    store.ingest(
        "corpus-registry",
        encode(
            {
                "version": 1,
                "updated": "2026-09-19T00:00:00Z",
                "subjects": [
                    {
                        "subject_id": "findings/org/repo",
                        "tree": "findings",
                        "ownership": "upstream",
                        "business_unit": "Storage Group",
                        "is_branch_audit": False,
                    }
                ],
            }
        ),
        Binding(),
    )
    rows = set(
        store.conn.execute("SELECT DISTINCT ownership, business_unit FROM current_finding")
    )
    assert rows == {("upstream", "Storage Group")}


def test_threats_are_keyed_on_key_not_in_model_id(store: Store) -> None:
    """Every threat model numbers its threats from T1.

    The fixture holds two different threats that are both `T1`. Key the
    projection on `id` and ~7,500 models collapse into one numbering space,
    keeping a single threat per number.
    """
    payload, _ = sample("threat-register")
    store.ingest("threat-register", payload, Binding())
    rows = store.conn.execute("SELECT threat_key, threat_id FROM threat").fetchall()
    assert len(rows) == 2
    assert {r[1] for r in rows} == {"T1"}, "both rows must share the in-model id"
    assert len({r[0] for r in rows}) == 2, "and still be distinct"


def test_reimporting_the_threat_register_does_not_double_threats(store: Store) -> None:
    """Same aggregate-restatement shape as corpus-registry.

    The register restates every threat on each regeneration and carries an
    `updated` timestamp, so its rows accumulate per binding. Without
    threat_current the threat count multiplies by the number of imports.
    """
    payload, _ = sample("threat-register")
    store.ingest("threat-register", payload, Binding())
    before = store.conn.execute("SELECT COUNT(*) FROM threat_current").fetchone()[0]
    assert before == 2

    document = json.loads(payload)
    document["meta"]["generated"] = "2026-09-19"
    store.ingest("threat-register", encode(document), Binding())

    assert store.conn.execute("SELECT COUNT(*) FROM threat").fetchone()[0] == 4
    assert store.conn.execute("SELECT COUNT(*) FROM threat_current").fetchone()[0] == before


def test_threat_exposure_keeps_partially_mitigated_and_marks_evidence(store: Store) -> None:
    """Two collapses that would each overstate coverage.

    partially_mitigated is the largest status bucket in the real register
    (45,273 of 82,850), and a threat with no evidence is modelled rather
    than proven -- a different claim from unmitigated.
    """
    payload, _ = sample("threat-register")
    store.ingest("threat-register", payload, Binding())
    rows = store.query_threat_exposure(["local"])
    by_status = {row[7]: row[8] for row in rows}
    assert set(by_status) == {"unmitigated", "partially_mitigated"}
    assert by_status["unmitigated"] == 1, "the evidenced threat"
    assert by_status["partially_mitigated"] == 0, "no evidence on that one"


def test_operator_privilege_flags_follow_rbac_flag_presence(store: Store) -> None:
    """A flag key appears ONLY when it matched, so presence is the signal.

    The fixture matches two of the seven patterns; the other five must read
    as 0 rather than NULL, or a dashboard filter drops the row entirely.
    """
    payload, _ = sample("operator-priv-profile")
    store.ingest(
        "operator-priv-profile",
        payload,
        Binding(subject_id="findings/example/repo", run_id="r1"),
    )
    rows = store.query_operator_privilege(["local"])
    assert len(rows) == 1
    columns = [
        description[0]
        for description in store.conn.execute(
            "SELECT * FROM operator_privilege LIMIT 1"
        ).description
    ]
    row = dict(zip(columns, rows[0], strict=True))
    assert row["flag_secrets_access"] == 1
    assert row["flag_escalate_bind_impersonate"] == 1
    for absent in ("nodes_access", "wildcard_verbs", "wildcard_resources",
                   "pods_exec", "rbac_write"):
        assert row[f"flag_{absent}"] == 0, absent


def test_priv_profile_lifts_summary_counts_into_columns(store: Store) -> None:
    """The dashboard cuts by these, so leaving them in the blob means every
    consumer re-derives them."""
    payload, _ = sample("operator-priv-profile")
    store.ingest(
        "operator-priv-profile",
        payload,
        Binding(subject_id="findings/example/repo", run_id="r1"),
    )
    row = store.conn.execute(
        "SELECT workload_count, privileged_or_host_workloads, rbac_rule_count, "
        "distinct_rule_triples, no_scc_request_recorded FROM priv_profile"
    ).fetchone()
    assert row == (2, 0, 1, 2, 1)


def test_every_dashboard_read_refuses_an_empty_scope(store: Store) -> None:
    """PostgreSQL fails closed, so an empty scope reads as 'no findings'
    when it means 'misconfigured'."""
    _seed_dashboard(store)
    for read in (
        store.query_open_findings,
        store.query_hardening_findings,
        store.query_distinct_exposure,
        store.query_census_population,
        store.query_census_exposure,
        store.query_threat_current,
        store.query_threat_exposure,
        store.query_operator_privilege,
    ):
        with pytest.raises(IngestError, match="scope is required"):
            read([])
        assert read(["other-scope"]) == []
