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
from storage_samples import FAMILIES, PROJECTION_TABLES, RUN_BOUND, encode, sample

from traust_contracts.v1.storage import Binding, IngestError, Store, binding_id
from traust_contracts.v1.storage.sql import CONTRACT_VERSION, REVISION

TABLES = ["artifact_binding", "artifact_evidence", *sorted(set(PROJECTION_TABLES.values()))]


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
    assert count == (2 if name == "vuln-findings" else 1)


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
    finding_payload, _ = sample("vuln-findings")
    triage_document = json.loads(sample("triage")[0])
    triage_document["findings"][0]["orig_id"] = "REPO-abcdef0-001"
    layer_payload, _ = sample("layer")
    context = run_binding(layer="ledger:layer:1")
    store.ingest("vuln-findings", finding_payload, context)
    store.ingest("triage", encode(triage_document), context)
    store.ingest("layer", layer_payload, Binding(layer_id="ledger:layer:1"))
    rows = store.query_findings_summary(["local"])
    assert [(row[4], row[5], row[6], row[7]) for row in rows] == [
        ("https://example.test/repo", "high", "true_positive", 1),
        ("https://example.test/repo", "low", None, 1),
    ]
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
