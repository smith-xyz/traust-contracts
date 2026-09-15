"""Executed protocol: evidence, extraction, isolation, races and view semantics."""

from __future__ import annotations

import hashlib
import json
import logging
import sqlite3
from collections.abc import Iterator
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from threading import Barrier
from typing import Any

import pytest
from storage_samples import FAMILIES, PROJECTION_TABLES, encode, sample

from traust_contracts.v1.storage import IngestError, Store
from traust_contracts.v1.storage.sql import CONTRACT_VERSION, REVISION

TABLES = ["artifact", *sorted(set(PROJECTION_TABLES.values()))]


@pytest.fixture
def store() -> Iterator[Store]:
    conn = sqlite3.connect(":memory:")
    store = Store(conn)
    store.init()
    yield store
    conn.close()


def assert_empty(store: Store) -> None:
    for name in TABLES:
        assert store.conn.execute(f"SELECT count(*) FROM {name}").fetchone()[0] == 0


def test_init_revision_semantics(store: Store) -> None:
    conn = store.conn
    names = {r[0] for r in conn.execute("SELECT name FROM sqlite_master WHERE type='table'")}
    assert names == {*TABLES, "traust_storage_meta"}
    indexes = {
        row[0]
        for row in conn.execute(
            "SELECT name FROM sqlite_master WHERE type='index' "
            "AND name NOT LIKE 'sqlite_autoindex%'"
        )
    }
    parent_tables = set(PROJECTION_TABLES.values()) - {
        "finding",
        "layer_metadata",
        "triage_verdict",
    }
    assert indexes == {
        "idx_artifact_layer",
        "idx_artifact_name",
        "idx_finding_artifact",
        "idx_finding_severity",
        "idx_layer_metadata_artifact",
        "idx_layer_metadata_project",
        "idx_triage_verdict",
        "idx_triage_verdict_artifact",
        *(f"idx_{table}_{suffix}" for table in parent_tables for suffix in ["artifact", "project"]),
    }
    assert conn.execute("SELECT name FROM sqlite_master WHERE type='view'").fetchall() == [
        ("compliance_dashboard",)
    ]
    original = conn.execute("SELECT * FROM traust_storage_meta").fetchall()
    assert len(original) == 1 and original[0][:3] == (1, CONTRACT_VERSION, REVISION)
    store.init()
    assert conn.execute("SELECT * FROM traust_storage_meta").fetchall() == original
    conn.execute("UPDATE traust_storage_meta SET revision=?", (REVISION + 1,))
    conn.commit()
    with pytest.raises(IngestError, match=f"revision {REVISION + 1}.*revision {REVISION}"):
        store.init()
    assert conn.execute("SELECT revision FROM traust_storage_meta").fetchone()[0] == REVISION + 1
    conn.execute("UPDATE traust_storage_meta SET revision=0, applied_at='old'")
    conn.commit()
    with pytest.raises(IngestError, match=rf"revision 0.*revision {REVISION}.*migration"):
        store.init()
    assert conn.execute("SELECT revision, applied_at FROM traust_storage_meta").fetchone() == (
        0,
        "old",
    )
    conn.execute("UPDATE traust_storage_meta SET contract_version='v99'")
    conn.commit()
    with pytest.raises(IngestError, match=r"v99.*v1"):
        store.init()


@pytest.mark.parametrize("name", FAMILIES)
def test_exact_evidence_and_counts(store: Store, name: str) -> None:
    payload, meta = sample(name)
    result = store.ingest(name, payload, meta)
    projection = {PROJECTION_TABLES[name]: 2 if name == "vuln-findings" else 1}
    assert result.tables == {"artifact": 1, **projection}
    raw, digest, timestamp = store.conn.execute(
        "SELECT payload, digest, ingested_at FROM artifact"
    ).fetchone()
    assert raw == payload and hashlib.sha256(raw).hexdigest() == digest == result.digest
    assert timestamp.endswith("+00:00")
    assert store.conn.execute("SELECT project_id FROM artifact").fetchone()[0] == "local"


def test_real_sample_smoke(store: Store) -> None:
    """Unchanged gcp-project-operator-vuln-findings.json from the original storage corpus.

    Source: hybrid-platforms-sec/analysis-results/findings/osd-operators/
    gcp-project-operator; all five findings retained, no synthetic substitutions.
    """
    payload = (Path(__file__).parent / "fixtures/storage/real-vuln-findings.json").read_bytes()
    result = store.ingest("vuln-findings", payload, {"layer_id": "real"})
    assert result.tables == {"artifact": 1, "finding": 5}
    assert store.conn.execute("SELECT payload FROM artifact").fetchone()[0] == payload


@pytest.mark.parametrize("payload", [b"{", b"{}", b"\xff", b'{"findings": NaN}'])
def test_invalid_bytes_are_owned_by_error_and_write_nothing(store: Store, payload: bytes) -> None:
    with pytest.raises(IngestError, match="validation") as caught:
        store.ingest("vuln-findings", payload)
    assert caught.value.payload is payload and caught.value.artifact == "vuln-findings"
    assert caught.value.__cause__ is None
    assert caught.value.__suppress_context__
    assert_empty(store)
    assert not store.conn.in_transaction


@pytest.mark.parametrize("line", [1, 1.0, 1e3])
def test_integral_json_number_projection(store: Store, line: int | float) -> None:
    payload, meta = sample("vuln-findings")
    doc = json.loads(payload)
    doc["findings"][0]["line"] = line
    raw = encode(doc)
    store.ingest("vuln-findings", raw, meta)
    row = store.conn.execute(
        "SELECT line FROM finding WHERE finding_id=?", (doc["findings"][0]["id"],)
    ).fetchone()
    assert row == (int(line),) and type(row[0]) is int
    assert store.conn.execute("SELECT payload FROM artifact").fetchone()[0] == raw


@pytest.mark.parametrize("value", [True, False, 1.5, float("inf"), float("nan")])
def test_integer_projection_rejects_nonintegers(store: Store, value: Any) -> None:
    payload, meta = sample("vuln-findings")
    document = json.loads(payload)
    document["findings"][0]["line"] = value
    with pytest.raises(IngestError, match="validation"):
        store.ingest("vuln-findings", encode(document), meta)
    assert_empty(store)


def test_unknown_artifact_and_bad_format(store: Store) -> None:
    with pytest.raises(IngestError, match="unknown artifact schema"):
        store.ingest("../layer", b"{}")
    doc = json.loads(sample("layer")[0])
    doc["metadata"]["created"] = "not-a-date"
    with pytest.raises(IngestError, match="schema rule format"):
        store.ingest("layer", encode(doc), {"layer_id": "L"})
    assert_empty(store)


def test_required_and_defaulted_metadata(store: Store) -> None:
    payload, meta = sample("vuln-findings")
    with pytest.raises(IngestError, match="table artifact, column layer_id, row 0"):
        store.ingest("vuln-findings", payload)
    assert_empty(store)
    with pytest.raises(IngestError, match="project_id"):
        store.ingest("vuln-findings", payload, {**meta, "project_id": None})
    assert_empty(store)
    store.ingest("vuln-findings", payload, {**meta, "project_id": "tenant-a"})
    assert store.conn.execute("SELECT project_id FROM artifact").fetchone()[0] == "tenant-a"


def test_idempotency_correction_and_old_digest_noop(store: Store) -> None:
    payload, meta = sample("vuln-findings")
    first = store.ingest("vuln-findings", payload, meta)
    before = list(store.conn.iterdump())
    repeat = store.ingest("vuln-findings", payload, {"layer_id": "different"})
    assert repeat.already_ingested and repeat.tables == {} and repeat.digest == first.digest
    assert list(store.conn.iterdump()) == before
    doc = json.loads(payload)
    doc["findings"][0]["title"] = "Corrected finding title"
    corrected = store.ingest("vuln-findings", encode(doc), meta)
    assert corrected.digest != first.digest and not corrected.already_ingested
    assert store.conn.execute("SELECT count(*) FROM finding").fetchone()[0] == 2
    assert store.conn.execute("SELECT DISTINCT artifact_digest FROM finding").fetchall() == [
        (corrected.digest,)
    ]
    assert store.conn.execute("SELECT count(*) FROM artifact").fetchone()[0] == 2
    state = list(store.conn.iterdump())
    assert store.ingest("vuln-findings", payload, meta).already_ingested
    assert list(store.conn.iterdump()) == state


def test_schema_invalid_second_row_aborts_at_door(store: Store) -> None:
    payload, meta = sample("vuln-findings")
    doc = json.loads(payload)
    doc["findings"][1]["severity"] = "invented"
    with pytest.raises(IngestError, match="validation"):
        store.ingest("vuln-findings", encode(doc), meta)
    assert_empty(store)


def test_mid_artifact_database_failure_rolls_back_prior_rows(store: Store) -> None:
    payload, meta = sample("vuln-findings")
    second = json.loads(payload)["findings"][1]["id"]
    store.conn.execute(
        "CREATE TRIGGER fail_second BEFORE INSERT ON finding "
        f"WHEN NEW.finding_id='{second}' BEGIN SELECT RAISE(ABORT, 'second row failure'); END"
    )
    with pytest.raises(IngestError, match=r"table finding.*row 1.*IntegrityError") as caught:
        store.ingest("vuln-findings", payload, meta)
    assert caught.value.payload == payload
    assert_empty(store)
    assert not store.conn.in_transaction


@pytest.mark.parametrize("operation", ["init", "ingest"])
def test_caller_transaction_never_committed_or_rolled_back(store: Store, operation: str) -> None:
    store.conn.execute("CREATE TABLE caller_work (value TEXT)")
    store.conn.execute("INSERT INTO caller_work VALUES ('uncommitted')")
    traced = []
    store.conn.set_trace_callback(traced.append)
    with pytest.raises(IngestError, match="caller transaction is untouched"):
        if operation == "init":
            store.init()
        else:
            store.ingest("vuln-findings", *sample("vuln-findings"))
    assert traced == []
    assert store.conn.in_transaction
    assert store.conn.execute("SELECT * FROM caller_work").fetchall() == [("uncommitted",)]
    store.conn.rollback()
    assert store.conn.execute("SELECT * FROM caller_work").fetchall() == []


def test_concurrent_duplicate_is_exact_noop(tmp_path: Path) -> None:
    path = tmp_path / "race.sqlite"
    conn = sqlite3.connect(path)
    Store(conn).init()
    conn.close()
    barrier = Barrier(2)
    payload, meta = sample("vuln-findings")

    def ingest() -> Any:
        connection = sqlite3.connect(path, timeout=10)
        try:
            barrier.wait(timeout=10)
            return Store(connection).ingest("vuln-findings", payload, meta)
        finally:
            connection.close()

    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(lambda _: ingest(), range(2)))
    assert sorted(r.already_ingested for r in results) == [False, True]
    assert next(r for r in results if r.already_ingested).tables == {}
    conn = sqlite3.connect(path)
    try:
        assert conn.execute("SELECT count(*) FROM artifact").fetchone()[0] == 1
        assert conn.execute("SELECT count(*) FROM finding").fetchone()[0] == 2
    finally:
        conn.close()


@pytest.mark.parametrize("omit", [None, *FAMILIES])
def test_dashboard_counts_and_partial_siblings(store: Store, omit: str | None) -> None:
    for name in FAMILIES:
        if name != omit:
            store.ingest(name, *sample(name))
    rows = store.conn.execute(
        "SELECT project_id, repo, severity, verdict, finding_count "
        "FROM compliance_dashboard ORDER BY severity"
    ).fetchall()
    expected = (
        []
        if omit in {"layer", "vuln-findings"}
        else [
            ("local", "https://example.test/repo", "high", None, 1),
            ("local", "https://example.test/repo", "low", None, 1),
        ]
    )
    assert rows == expected


def test_source_id_join_missing_orig_id_and_duplicate_references(store: Store) -> None:
    for name in ["layer", "vuln-findings"]:
        store.ingest(name, *sample(name))
    payload, meta = sample("triage")
    doc = json.loads(payload)
    source = json.loads(sample("vuln-findings")[0])["findings"][0]
    doc["findings"][0]["orig_id"] = source["id"]
    assert doc["findings"][0]["id"] != source["id"]
    duplicate = {**doc["findings"][0], "id": "f999"}
    doc["findings"].append(duplicate)
    store.ingest("triage", encode(doc), meta)
    rows = store.conn.execute(
        "SELECT severity, verdict, finding_count FROM compliance_dashboard ORDER BY severity"
    ).fetchall()
    assert rows == [(source["severity"], duplicate["verdict"], 1), ("low", None, 1)]


@pytest.mark.parametrize("explicit_null", [False, True])
def test_optional_triage_fields_map_to_sql_null(store: Store, explicit_null: bool) -> None:
    payload, meta = sample("triage")
    doc = json.loads(payload)
    finding = doc["findings"][0]
    for key in ["orig_id", "severity", "vote_breakdown", "rationale"]:
        if explicit_null:
            finding[key] = None
        else:
            finding.pop(key, None)
    store.ingest("triage", encode(doc), meta)
    assert store.conn.execute(
        "SELECT source_finding_id, severity, vote_breakdown, rationale FROM triage_verdict"
    ).fetchone() == (None, None, None, None)


def test_projection_values_and_json_text(store: Store) -> None:
    for name in FAMILIES:
        store.ingest(name, *sample(name))
    assert store.conn.execute(
        "SELECT repo, created_at, merkle_root, merkle_epoch FROM layer_metadata"
    ).fetchone() == ("https://example.test/repo", "2026-01-01T00:00:00Z", None, None)
    assert store.conn.execute(
        "SELECT target, file, line, cwe, confidence FROM finding ORDER BY finding_id"
    ).fetchall() == [
        ("example/repo", "auth.py", 1, None, 0.9),
        ("example/repo", "debug.py", None, None, 0.5),
    ]
    assert store.conn.execute(
        "SELECT triage_completed, vote_breakdown, rationale FROM triage_verdict"
    ).fetchone() == (
        "2026-01-02",
        '{"true_positive":1,"hardening":0,"false_positive":0,"cannot_verify":0}',
        "Confirmed with a second account; café test.",
    )


@pytest.mark.parametrize("epoch", [1, 1.0, 1e3])
def test_integral_layer_epoch(store: Store, epoch: int | float) -> None:
    payload, meta = sample("layer")
    doc = json.loads(payload)
    doc["metadata"]["merkle_epoch"] = epoch
    store.ingest("layer", encode(doc), meta)
    assert store.conn.execute("SELECT merkle_epoch FROM layer_metadata").fetchone() == (int(epoch),)


def test_unsupported_connection() -> None:
    with pytest.raises(ValueError, match="Connection"):
        Store(object())


@pytest.mark.parametrize("mode", [None, ""])
def test_driver_autocommit_modes(mode: str | None) -> None:
    conn = sqlite3.connect(":memory:", isolation_level=mode)
    try:
        store = Store(conn)
        store.init()
        store.ingest("vuln-findings", *sample("vuln-findings"))
        assert not conn.in_transaction
        assert store.ingest("vuln-findings", *sample("vuln-findings")).already_ingested
    finally:
        conn.close()


def test_begin_lock_failure_keeps_bytes(tmp_path: Path) -> None:
    path = tmp_path / "locked.sqlite"
    conn = sqlite3.connect(path)
    blocked = sqlite3.connect(path, timeout=0)
    try:
        Store(conn).init()
        conn.execute("BEGIN IMMEDIATE")
        payload, meta = sample("vuln-findings")
        with pytest.raises(IngestError, match=r"begin transaction.*SQLITE_BUSY") as caught:
            Store(blocked).ingest("vuln-findings", payload, meta)
        assert caught.value.payload == payload
        assert not blocked.in_transaction and conn.in_transaction
    finally:
        conn.close()
        blocked.close()


def test_database_auto_rollback_preserves_error_type(store: Store) -> None:
    store.conn.execute(
        "CREATE TRIGGER fail_insert BEFORE INSERT ON finding "
        "BEGIN SELECT RAISE(ROLLBACK, 'database rolled back'); END"
    )
    with pytest.raises(IngestError, match=r"IntegrityError.*SQLITE_CONSTRAINT_TRIGGER"):
        store.ingest("vuln-findings", *sample("vuln-findings"))
    assert_empty(store)


def test_connection_loss_does_not_hide_payload_or_error_type(
    store: Store,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    payload, meta = sample("vuln-findings")

    def disconnect(sql: str, values: Any = None) -> Any:
        store.conn.close()
        raise sqlite3.OperationalError("simulated connection loss")

    monkeypatch.setattr(store, "_execute", disconnect)
    with pytest.raises(IngestError, match=r"OperationalError.*rollback failed") as caught:
        store.ingest("vuln-findings", payload, meta)
    assert caught.value.payload == payload
    assert caught.value.__cause__ is None
    assert caught.value.__suppress_context__


def test_bootstrap_preserves_statement_boundaries_and_rolls_back(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    from traust_contracts.v1.storage.sql import bootstrap_files

    files = bootstrap_files("sqlite")
    extra = tmp_path / "extra.sql"
    extra.write_text("CREATE TABLE extra (value TEXT DEFAULT 'one;two');")
    trigger = tmp_path / "trigger.sql"
    trigger.write_text(
        "CREATE TRIGGER extra_insert AFTER INSERT ON extra BEGIN "
        "UPDATE extra SET value = 'three;four'; "
        "UPDATE extra SET value = value || ';five'; END;"
    )
    failure = tmp_path / "failure.sql"
    failure.write_text("SELECT * FROM missing_bootstrap_table;")
    conn = sqlite3.connect(":memory:")
    try:
        store = Store(conn)
        monkeypatch.setattr(
            "traust_contracts.v1.storage.store.bootstrap_files",
            lambda dialect: [*files, extra, trigger, failure],
        )
        with pytest.raises(IngestError, match=r"OperationalError.*SQLITE_ERROR"):
            store.init()
        assert not conn.in_transaction
        assert conn.execute("SELECT name FROM sqlite_master").fetchall() == []
        monkeypatch.setattr(
            "traust_contracts.v1.storage.store.bootstrap_files",
            lambda dialect: [*files, extra, trigger],
        )
        store.init()
        conn.execute("INSERT INTO extra DEFAULT VALUES")
        assert conn.execute("SELECT value FROM extra").fetchone() == ("three;four;five",)
        conn.rollback()
    finally:
        conn.close()


def test_revision_mismatch_never_runs_bootstrap(
    store: Store,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    store.conn.execute("UPDATE traust_storage_meta SET revision=0, applied_at='old'")
    store.conn.commit()

    def unexpected_bootstrap(dialect: str) -> list[Path]:
        pytest.fail("revision mismatch must not execute bootstrap")

    monkeypatch.setattr("traust_contracts.v1.storage.store.bootstrap_files", unexpected_bootstrap)
    with pytest.raises(IngestError, match="migration"):
        store.init()
    assert store.conn.execute(
        "SELECT revision, applied_at FROM traust_storage_meta"
    ).fetchone() == (0, "old")
    assert not store.conn.in_transaction


def test_correction_does_not_prune_omitted_rows(store: Store) -> None:
    payload, meta = sample("vuln-findings")
    first = store.ingest("vuln-findings", payload, meta)
    document = json.loads(payload)
    document["findings"].pop()
    correction = store.ingest("vuln-findings", encode(document), meta)
    assert store.conn.execute(
        "SELECT finding_id, artifact_digest FROM finding ORDER BY finding_id"
    ).fetchall() == [
        ("REPO-abcdef0-001", correction.digest),
        ("REPO-abcdef0-002", first.digest),
    ]


@pytest.mark.parametrize("name", ["vuln-findings", "triage"])
def test_empty_findings_retains_evidence(store: Store, name: str) -> None:
    payload, meta = sample(name)
    document = json.loads(payload)
    document["findings"] = []
    table = "finding" if name == "vuln-findings" else "triage_verdict"
    result = store.ingest(name, encode(document), meta)
    assert result.tables == {"artifact": 1, table: 0}
    assert store.conn.execute(f"SELECT count(*) FROM {table}").fetchone()[0] == 0


@pytest.mark.parametrize("field", ["layer_id", "project_id"])
@pytest.mark.parametrize("value", [None, 7, False])
def test_metadata_rejects_null_and_non_strings(store: Store, field: str, value: Any) -> None:
    payload, meta = sample("layer")
    with pytest.raises(IngestError, match=rf"column {field}, row 0") as caught:
        store.ingest("layer", payload, {**meta, field: value})
    assert caught.value.payload is payload
    assert_empty(store)


def test_parent_projection_retains_evidence(store: Store) -> None:
    payload = encode(
        {
            "version": 1,
            "registers": [
                {
                    "name": "example",
                    "repo": "https://example.test/repo",
                    "paths": ["docs/decisions"],
                    "pin": "abcdef0",
                }
            ],
        }
    )
    result = store.ingest("adr-registry", payload, {"layer_id": "L"})
    assert result.tables == {"artifact": 1, "adr_registry": 1}
    assert store.conn.execute("SELECT name, payload FROM artifact").fetchone() == (
        "adr-registry",
        payload,
    )
    assert store.conn.execute(
        "SELECT version, registers, artifact_digest FROM adr_registry"
    ).fetchone() == (
        1,
        '[{"name":"example","repo":"https://example.test/repo",'
        '"paths":["docs/decisions"],"pin":"abcdef0"}]',
        result.digest,
    )


@pytest.mark.parametrize("invalid", ["required", "enum", "json", "unknown-schema"])
def test_validation_logs_do_not_contain_evidence(
    store: Store, caplog: pytest.LogCaptureFixture, invalid: str
) -> None:
    marker = "PRIVATE_EVIDENCE_DO_NOT_LOG"
    document = json.loads(sample("vuln-findings")[0])
    document["findings"][0]["title"] = marker
    artifact = "vuln-findings"
    if invalid == "required":
        document.pop("target")
    elif invalid == "enum":
        document["findings"][0]["severity"] = marker
    elif invalid == "unknown-schema":
        artifact = marker
    payload = encode(document) if invalid != "json" else b'{"secret":"' + marker.encode()
    try:
        store.ingest(artifact, payload, {"layer_id": "L"})
    except IngestError as error:
        assert error.payload == payload and error.artifact == artifact
        assert marker not in str(error)
        logging.getLogger(__name__).exception("ingest failed")
    else:
        pytest.fail("invalid artifact accepted")
    assert marker not in caplog.text
    assert "validation" in caplog.text
    assert_empty(store)


@pytest.mark.parametrize("operation", ["write", "init", "connection-loss"])
def test_database_logs_do_not_contain_driver_details(
    store: Store,
    caplog: pytest.LogCaptureFixture,
    monkeypatch: pytest.MonkeyPatch,
    operation: str,
) -> None:
    marker = "PRIVATE_DATABASE_DETAIL"
    payload, meta = sample("vuln-findings")
    if operation == "write":
        store.conn.execute(
            "CREATE TRIGGER reject_finding BEFORE INSERT ON finding "
            f"BEGIN SELECT RAISE(ABORT, '{marker}'); END"
        )
    else:

        def failure(sql: str, values: Any = None) -> Any:
            if operation == "connection-loss":
                store.conn.close()
            raise sqlite3.OperationalError(marker)

        monkeypatch.setattr(store, "_execute", failure)
    try:
        if operation == "init":
            store.init()
        else:
            store.ingest("vuln-findings", payload, meta)
    except IngestError as error:
        if operation != "init":
            assert error.payload == payload
        assert marker not in str(error)
        logging.getLogger(__name__).exception("store failed")
    else:
        pytest.fail("database error ignored")
    assert marker not in caplog.text
    if operation != "connection-loss":
        assert not store.conn.in_transaction
        assert_empty(store)


def test_all_parent_projection_values_and_canonical_json(store: Store) -> None:
    from traust_contracts.v1.storage.store import ONE_ROW_PROJECTIONS

    assert set(ONE_ROW_PROJECTIONS) == set(FAMILIES) - {"layer", "triage", "vuln-findings"}
    for name, (table, fields) in ONE_ROW_PROJECTIONS.items():
        payload, meta = sample(name)
        document = json.loads(payload)
        result = store.ingest(name, payload, {**meta, "layer_id": name})
        columns = [field for field, _ in fields]
        row = store.conn.execute(
            f"SELECT {', '.join(columns)}, layer_id, project_id, artifact_digest FROM {table}"
        ).fetchone()
        expected = []
        for field, kind in fields:
            value = document.get(field)
            if kind == "json" and value is not None:
                value = json.dumps(value, ensure_ascii=False, separators=(",", ":"))
            expected.append(value)
        assert row == (*expected, name, "local", result.digest)
