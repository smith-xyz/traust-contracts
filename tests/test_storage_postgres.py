"""Real-server checks using an explicitly configured, reachable PostgreSQL database.

Creates and removes a private schema per test; never touches existing tables.
"""

from __future__ import annotations

import json
import logging
from collections.abc import Iterator
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from threading import Barrier
from typing import Any
from uuid import uuid4

import pytest
from storage_samples import FAMILIES, PROJECTION_TABLES, encode, sample

from traust_contracts.v1.storage import IngestError, Store
from traust_contracts.v1.storage.sql import REVISION


@pytest.fixture(params=[False, True], ids=["transactional-driver", "autocommit-driver"])
def database(request: pytest.FixtureRequest, postgres_dsn: str) -> Iterator[tuple[Any, str]]:
    import psycopg
    from psycopg import sql

    conn = psycopg.connect(postgres_dsn, autocommit=True, connect_timeout=2)
    schema = "storage_test_" + uuid4().hex
    conn.execute(sql.SQL("CREATE SCHEMA {}").format(sql.Identifier(schema)))
    conn.execute(sql.SQL("SET search_path TO {}").format(sql.Identifier(schema)))
    conn.autocommit = request.param
    try:
        yield conn, schema
    finally:
        conn.rollback()
        conn.autocommit = True
        conn.execute(sql.SQL("DROP SCHEMA {} CASCADE").format(sql.Identifier(schema)))
        conn.close()


@pytest.mark.parametrize("number", [1, 1.0, 1e3])
def test_postgres_integral_json_number_projection(
    database: tuple[Any, str],
    number: int | float,
) -> None:
    conn, _ = database
    store = Store(conn)
    store.init()
    document = json.loads(sample("vuln-findings")[0])
    document["findings"][0]["line"] = number
    payload = json.dumps(document).encode()
    store.ingest("vuln-findings", payload, {"layer_id": "L"})
    row = conn.execute(
        "SELECT line FROM finding WHERE finding_id=%s", (document["findings"][0]["id"],)
    ).fetchone()
    assert row == (int(number),) and type(row[0]) is int
    assert conn.execute("SELECT payload FROM artifact").fetchone()[0] == payload
    conn.commit()
    document = json.loads(sample("layer")[0])
    document["metadata"]["merkle_epoch"] = number
    store.ingest("layer", encode(document), {"layer_id": "L"})
    assert conn.execute("SELECT merkle_epoch FROM layer_metadata").fetchone() == (int(number),)
    conn.commit()


def test_postgres_roundtrip_and_noop(database: tuple[Any, str]) -> None:
    conn, _ = database
    store = Store(conn)
    store.init()
    initial = conn.execute("SELECT * FROM traust_storage_meta").fetchall()
    projection_tables = set(PROJECTION_TABLES.values())
    assert conn.execute(
        "SELECT tablename FROM pg_tables WHERE schemaname = current_schema() ORDER BY tablename"
    ).fetchall() == [
        (name,) for name in sorted({"artifact", "traust_storage_meta", *projection_tables})
    ]
    parent_tables = projection_tables - {"finding", "layer_metadata", "triage_verdict"}
    expected_indexes = {
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
    assert conn.execute(
        "SELECT indexname FROM pg_indexes "
        "WHERE schemaname = current_schema() AND indexname LIKE 'idx_%' ORDER BY indexname"
    ).fetchall() == [(name,) for name in sorted(expected_indexes)]
    conn.commit()
    store.init()
    assert conn.execute("SELECT * FROM traust_storage_meta").fetchall() == initial
    conn.commit()
    for name in FAMILIES:
        payload, meta = sample(name)
        result = store.ingest(name, payload, meta)
        projection = {PROJECTION_TABLES[name]: 2 if name == "vuln-findings" else 1}
        assert result.tables == {"artifact": 1, **projection}
        raw, stamp = conn.execute(
            "SELECT payload, ingested_at FROM artifact WHERE digest=%s", (result.digest,)
        ).fetchone()
        assert raw == payload
        conn.commit()
        assert store.ingest(name, payload, meta).already_ingested
        assert (
            conn.execute(
                "SELECT ingested_at FROM artifact WHERE digest=%s", (result.digest,)
            ).fetchone()[0]
            == stamp
        )
        conn.commit()
    assert conn.execute("SELECT vote_breakdown FROM triage_verdict").fetchone()[0] == {
        "true_positive": 1,
        "hardening": 0,
        "false_positive": 0,
        "cannot_verify": 0,
    }
    conn.execute("SET traust.project_ids = '{local}'")
    assert conn.execute(
        "SELECT relkind, reloptions FROM pg_class WHERE oid = 'compliance_dashboard'::regclass"
    ).fetchone() == ("v", ["security_barrier=true"])
    assert conn.execute("SELECT to_regclass('compliance_dashboard_mv')").fetchone() == (None,)
    assert conn.execute(
        "SELECT project_id, repo, severity, verdict, finding_count "
        "FROM compliance_dashboard ORDER BY severity"
    ).fetchall() == [
        ("local", "https://example.test/repo", "high", None, 1),
        ("local", "https://example.test/repo", "low", None, 1),
    ]
    conn.execute("SET traust.project_ids = '{other}'")
    assert conn.execute("SELECT * FROM compliance_dashboard").fetchall() == []
    conn.commit()
    conn.execute("UPDATE traust_storage_meta SET revision=%s", (REVISION + 1,))
    conn.commit()
    with pytest.raises(IngestError, match=f"revision {REVISION + 1}.*revision {REVISION}"):
        store.init()


def test_postgres_atomic_failure_and_caller_transaction(database: tuple[Any, str]) -> None:
    conn, _ = database
    store = Store(conn)
    store.init()
    payload = sample("vuln-findings")[0]
    second = json.loads(payload)["findings"][1]["id"]
    from psycopg import sql

    conn.execute(
        sql.SQL("ALTER TABLE finding ADD CHECK (finding_id <> {})").format(sql.Literal(second))
    )
    conn.commit()
    with pytest.raises(IngestError, match=r"table finding.*row 1"):
        store.ingest("vuln-findings", payload, {"layer_id": "L"})
    assert conn.execute("SELECT count(*) FROM artifact").fetchone()[0] == 0
    assert conn.execute("SELECT count(*) FROM finding").fetchone()[0] == 0
    conn.commit()
    conn.execute("BEGIN")
    conn.execute("UPDATE traust_storage_meta SET applied_at='2000-01-01T00:00:00Z'")
    with pytest.raises(IngestError, match="caller transaction is untouched"):
        store.ingest("vuln-findings", payload, {"layer_id": "L"})
    assert conn.info.transaction_status == 2
    conn.execute("ROLLBACK")
    with pytest.raises(IngestError, match="validation"):
        store.ingest("vuln-findings", b"{}")


def test_postgres_concurrent_duplicate(database: tuple[Any, str], postgres_dsn: str) -> None:
    import psycopg

    conn, schema = database
    Store(conn).init()
    payload = sample("vuln-findings")[0]
    barrier = Barrier(2)

    def ingest() -> Any:
        with psycopg.connect(postgres_dsn, options=f"-csearch_path={schema}") as peer:
            peer.isolation_level = psycopg.IsolationLevel.REPEATABLE_READ
            barrier.wait(timeout=10)
            return Store(peer).ingest("vuln-findings", payload, {"layer_id": "L"})

    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(lambda _: ingest(), range(2)))
    assert sorted(r.already_ingested for r in results) == [False, True]
    assert next(r for r in results if r.already_ingested).tables == {}
    assert conn.execute("SELECT count(*) FROM artifact").fetchone()[0] == 1
    assert conn.execute("SELECT count(*) FROM finding").fetchone()[0] == 2


@pytest.mark.parametrize("omit", [None, *FAMILIES])
def test_postgres_join_and_missing_siblings(database: tuple[Any, str], omit: str | None) -> None:
    conn, _ = database
    store = Store(conn)
    store.init()
    for name in FAMILIES:
        if name == omit:
            continue
        payload, meta = sample(name)
        if name == "triage":
            document = json.loads(payload)
            document["findings"][0]["orig_id"] = "REPO-abcdef0-001"
            document["findings"].append({**document["findings"][0], "id": "f999"})
            payload = encode(document)
        store.ingest(name, payload, meta)
    conn.execute("SET traust.project_ids = '{local}'")
    expected = (
        []
        if omit in {"layer", "vuln-findings"}
        else [
            ("high", None if omit == "triage" else "true_positive", 1),
            ("low", None, 1),
        ]
    )
    assert (
        conn.execute(
            "SELECT severity, verdict, finding_count FROM compliance_dashboard ORDER BY severity"
        ).fetchall()
        == expected
    )
    conn.commit()


def test_postgres_bootstrap_failure_is_atomic(
    database: tuple[Any, str],
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    from traust_contracts.v1.storage.sql import bootstrap_files

    conn, _ = database
    files = bootstrap_files("postgres")
    extra = tmp_path / "extra.sql"
    extra.write_text("CREATE TABLE extra (value TEXT DEFAULT 'one;two');")
    failure = tmp_path / "failure.sql"
    failure.write_text("SELECT * FROM missing_bootstrap_table;")
    monkeypatch.setattr(
        "traust_contracts.v1.storage.store.bootstrap_files",
        lambda dialect: [*files, extra, failure],
    )
    with pytest.raises(IngestError, match=r"UndefinedTable.*42P01"):
        Store(conn).init()
    assert conn.info.transaction_status == 0
    assert conn.execute("SELECT to_regclass('artifact'), to_regclass('extra')").fetchone() == (
        None,
        None,
    )
    conn.commit()
    monkeypatch.setattr(
        "traust_contracts.v1.storage.store.bootstrap_files",
        lambda dialect: [*files, extra],
    )
    Store(conn).init()
    assert conn.execute("INSERT INTO extra DEFAULT VALUES RETURNING value").fetchone() == (
        "one;two",
    )
    conn.commit()


@pytest.mark.parametrize("operation", ["init", "ingest"])
def test_postgres_caller_rollback_is_untouched(database: tuple[Any, str], operation: str) -> None:
    conn, _ = database
    store = Store(conn)
    store.init()
    conn.execute("CREATE TABLE caller_work (value TEXT)")
    conn.commit()
    conn.execute("BEGIN")
    conn.execute("INSERT INTO caller_work VALUES ('uncommitted')")
    with pytest.raises(IngestError, match="caller transaction is untouched"):
        if operation == "init":
            store.init()
        else:
            store.ingest("vuln-findings", *sample("vuln-findings"))
    assert conn.execute("SELECT * FROM caller_work").fetchall() == [("uncommitted",)]
    conn.execute("ROLLBACK")
    assert conn.execute("SELECT * FROM caller_work").fetchall() == []
    conn.commit()


@pytest.mark.parametrize("revision", [0, REVISION + 1])
def test_postgres_revision_mismatch_preserves_database(
    database: tuple[Any, str], revision: int
) -> None:
    conn, _ = database
    store = Store(conn)
    store.init()
    conn.execute("UPDATE traust_storage_meta SET revision=%s", (revision,))
    before = conn.execute("SELECT * FROM traust_storage_meta").fetchall()
    conn.commit()
    with pytest.raises(IngestError, match=rf"revision {revision}.*revision {REVISION}.*migration"):
        store.init()
    assert conn.execute("SELECT * FROM traust_storage_meta").fetchall() == before
    conn.commit()


def test_postgres_dashboard_is_live_and_scoped(database: tuple[Any, str]) -> None:
    import psycopg

    conn, _ = database
    store = Store(conn)
    store.init()
    for project in ["a", "b"]:
        for name in ["layer", "vuln-findings"]:
            document = json.loads(sample(name)[0])
            if name == "layer":
                document["metadata"]["repository"] = f"https://example.test/{project}"
            else:
                document["target"] = project
            store.ingest(name, encode(document), {"layer_id": project, "project_id": project})
    with pytest.raises(psycopg.Error):
        conn.execute("SELECT * FROM compliance_dashboard").fetchall()
    conn.rollback()
    for project in ["a", "b"]:
        conn.execute("SELECT set_config('traust.project_ids', %s, false)", ("{" + project + "}",))
        rows = conn.execute(
            "SELECT project_id, SUM(finding_count) FROM compliance_dashboard GROUP BY project_id"
        ).fetchall()
        assert rows == [(project, 2)]
    conn.execute("SET traust.project_ids = '{a}'")
    conn.commit()
    document = json.loads(sample("vuln-findings")[0])
    document["target"] = "a"
    document["findings"][0]["severity"] = "critical"
    store.ingest("vuln-findings", encode(document), {"layer_id": "a", "project_id": "a"})
    assert conn.execute(
        "SELECT severity, finding_count FROM compliance_dashboard ORDER BY severity"
    ).fetchall() == [("critical", 1), ("low", 1)]
    conn.commit()


def test_postgres_constraint_errors_do_not_log_evidence(
    database: tuple[Any, str], caplog: pytest.LogCaptureFixture
) -> None:
    from psycopg import sql

    conn, _ = database
    store = Store(conn)
    store.init()
    marker = "PRIVATE_ROW_CONTENT"
    conn.execute(sql.SQL("ALTER TABLE finding ADD CHECK (title <> {})").format(sql.Literal(marker)))
    conn.commit()
    document = json.loads(sample("vuln-findings")[0])
    document["findings"][0]["title"] = marker
    payload = encode(document)
    try:
        store.ingest("vuln-findings", payload, {"layer_id": "L"})
    except IngestError as error:
        assert error.payload == payload
        assert "23514" in str(error)
        logging.getLogger(__name__).exception("ingest failed")
    else:
        pytest.fail("constraint failure was ignored")
    assert marker not in caplog.text
    assert conn.execute("SELECT count(*) FROM artifact").fetchone() == (0,)
    conn.commit()
