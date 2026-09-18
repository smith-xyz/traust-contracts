"""Real-server checks using the fixed reachable PostgreSQL test database."""

from __future__ import annotations

import json
from collections.abc import Iterator
from concurrent.futures import ThreadPoolExecutor
from threading import Barrier
from typing import Any
from uuid import uuid4

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

from traust_contracts.v1.storage import Binding, IngestError, Store
from traust_contracts.v1.storage.sql import REVISION

TABLES = {
    "artifact_binding",
    "artifact_evidence",
    "traust_storage_meta",
    *PROJECTION_TABLES.values(),
    *SECONDARY_PROJECTION_TABLES.values(),
}


@pytest.fixture(params=[False, True], ids=["transactional-driver", "autocommit-driver"])
def database(request: pytest.FixtureRequest, postgres_dsn: str) -> Iterator[tuple[Any, str]]:
    import psycopg
    from psycopg import sql

    conn = psycopg.connect(postgres_dsn, autocommit=True, connect_timeout=2)
    schema = "storage_test_" + uuid4().hex
    conn.execute("DROP SCHEMA IF EXISTS traust_storage CASCADE")
    conn.execute(sql.SQL("CREATE SCHEMA {} ").format(sql.Identifier(schema)))
    conn.execute(sql.SQL("SET search_path TO {}, traust_storage").format(sql.Identifier(schema)))
    conn.autocommit = request.param
    try:
        yield conn, schema
    finally:
        conn.rollback()
        conn.autocommit = True
        conn.execute("DROP SCHEMA IF EXISTS traust_storage CASCADE")
        conn.execute(sql.SQL("DROP SCHEMA {} CASCADE").format(sql.Identifier(schema)))
        conn.close()


def run_binding(
    *, scope: str = "local", layer: str | None = None, supersedes: str | None = None
) -> Binding:
    return Binding(scope, "sci:inventory-item:42", "sci:scan-result:7", layer, supersedes)


def binding_for(name: str) -> Binding:
    if name in RUN_BOUND:
        return run_binding()
    if name == "layer":
        return Binding(layer_id="ledger:layer:1")
    return Binding()


def test_postgres_shape_roundtrip_and_binding_noop(database: tuple[Any, str]) -> None:
    conn, _ = database
    store = Store(conn)
    store.init()
    assert {
        row[0]
        for row in conn.execute(
            "SELECT tablename FROM pg_tables WHERE schemaname = 'traust_storage'"
        ).fetchall()
    } == TABLES
    conn.commit()
    for name in FAMILIES:
        payload, _ = sample(name)
        result = store.ingest(name, payload, binding_for(name))
        assert store.get_evidence(result.digest) == payload
        assert store.get(name, result.binding_id) == payload
        retry = store.ingest(name, payload, binding_for(name))
        assert retry.already_bound and retry.binding_id == result.binding_id
    assert conn.execute("SELECT count(*) FROM artifact_binding").fetchone() == (len(FAMILIES),)
    for name, table in PROJECTION_TABLES.items():
        # Fan-out families project one row per item in their sample.
        expected = 2 if name in {"vuln-findings", "corpus-registry"} else 1
        assert conn.execute(f"SELECT count(*) FROM {table}").fetchone() == (expected,)
    assert conn.execute(
        "SELECT reloptions FROM pg_class WHERE oid='findings_summary'::regclass"
    ).fetchone() == (["security_barrier=true"],)
    conn.commit()
    conn.execute("UPDATE traust_storage_meta SET revision=%s", (REVISION + 1,))
    conn.commit()
    with pytest.raises(IngestError, match="explicit migration"):
        store.init()


def test_postgres_storage_does_not_collide_with_application_tables(
    database: tuple[Any, str],
) -> None:
    conn, _ = database
    conn.execute("CREATE TABLE report (marker TEXT NOT NULL)")
    conn.execute("INSERT INTO report VALUES ('application-owned')")
    conn.commit()
    store = Store(conn)
    store.init()
    store.ingest("report", sample("report")[0], binding_for("report"))
    assert conn.execute("SELECT marker FROM report").fetchall() == [("application-owned",)]
    assert conn.execute("SELECT count(*) FROM traust_storage.report").fetchone() == (1,)
    conn.commit()


@pytest.mark.parametrize("number", [1, 1.0, 1e3])
def test_postgres_integral_projection(database: tuple[Any, str], number: int | float) -> None:
    conn, _ = database
    store = Store(conn)
    store.init()
    document = json.loads(sample("vuln-findings")[0])
    document["findings"][0]["line"] = number
    payload = json.dumps(document).encode()
    store.ingest("vuln-findings", payload, run_binding())
    assert conn.execute(
        "SELECT line FROM finding WHERE finding_id=%s",
        (document["findings"][0]["id"],),
    ).fetchone() == (int(number),)
    conn.commit()


def test_postgres_findings_summary_uses_json_scope_and_same_run(
    database: tuple[Any, str],
) -> None:
    conn, _ = database
    store = Store(conn)
    store.init()
    seed_findings_summary(store)
    assert store.query_findings_summary([FINDINGS_SUMMARY_SCOPE]) == FINDINGS_SUMMARY_ROWS
    assert store.query_findings_summary(["other"]) == []
    conn.execute("BEGIN READ ONLY")
    conn.execute("SELECT set_config('traust.scope_ids', %s, true)", ('["local"]',))
    assert conn.execute("SELECT count(*) FROM findings_summary").fetchone() == (2,)
    conn.execute("ROLLBACK")


def test_postgres_atomic_projection_failure(database: tuple[Any, str]) -> None:
    from psycopg import sql

    conn, _ = database
    store = Store(conn)
    store.init()
    payload = sample("vuln-findings")[0]
    second = json.loads(payload)["findings"][1]["id"]
    conn.execute(
        sql.SQL("ALTER TABLE finding ADD CHECK (finding_id <> {})").format(sql.Literal(second))
    )
    conn.commit()
    with pytest.raises(IngestError, match="23514"):
        store.ingest("vuln-findings", payload, run_binding())
    assert conn.execute("SELECT count(*) FROM artifact_evidence").fetchone() == (0,)
    assert conn.execute("SELECT count(*) FROM artifact_binding").fetchone() == (0,)
    conn.commit()


def test_postgres_supersession_is_explicit(database: tuple[Any, str]) -> None:
    conn, _ = database
    store = Store(conn)
    store.init()
    payload = sample("vuln-findings")[0]
    first = store.ingest("vuln-findings", payload, run_binding())
    corrected = json.loads(payload)
    corrected["findings"][0]["title"] = "Explicit corrected title"
    second = store.ingest(
        "vuln-findings",
        encode(corrected),
        run_binding(supersedes=first.binding_id),
    )
    assert conn.execute(
        "SELECT binding_id FROM current_binding WHERE artifact_name='vuln-findings'"
    ).fetchall() == [(second.binding_id,)]
    conn.commit()


def test_postgres_concurrent_same_binding(database: tuple[Any, str], postgres_dsn: str) -> None:
    import psycopg

    conn, schema = database
    Store(conn).init()
    payload = sample("vuln-findings")[0]
    barrier = Barrier(2)

    def ingest() -> Any:
        with psycopg.connect(postgres_dsn, options=f"-csearch_path={schema}") as peer:
            barrier.wait(timeout=10)
            return Store(peer).ingest("vuln-findings", payload, run_binding())

    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(lambda _: ingest(), range(2)))
    assert sorted(result.already_bound for result in results) == [False, True]
    assert conn.execute("SELECT count(*) FROM artifact_evidence").fetchone() == (1,)
    assert conn.execute("SELECT count(*) FROM artifact_binding").fetchone() == (1,)
    assert conn.execute("SELECT count(*) FROM finding").fetchone() == (2,)
    conn.commit()


def test_postgres_caller_transaction_is_untouched(database: tuple[Any, str]) -> None:
    conn, _ = database
    store = Store(conn)
    store.init()
    conn.execute("CREATE TABLE caller_work (value TEXT)")
    conn.commit()
    conn.execute("BEGIN")
    conn.execute("INSERT INTO caller_work VALUES ('uncommitted')")
    with pytest.raises(IngestError, match="caller transaction is untouched"):
        store.ingest("vuln-findings", sample("vuln-findings")[0], run_binding())
    assert conn.execute("SELECT * FROM caller_work").fetchall() == [("uncommitted",)]
    conn.execute("ROLLBACK")


def test_postgres_report_findings_match_sqlite_row_for_row(database: tuple[Any, str]) -> None:
    """GAP A/B on the other dialect, from the one shared fixture.

    SQLite stores the flags as 0/1 and PostgreSQL as booleans; the projection
    must still say the same thing about the same bytes. Comparing normalised
    values rather than raw driver types is the point -- a dialect that
    silently coerced an absent flag to False would diverge here.
    """
    conn, _ = database
    store = Store(conn)
    store.init()
    result = store.ingest("report", report_with_findings(), run_binding())

    rows = conn.execute(
        "SELECT finding_id, fingerprint, validity, resolution, assurance, "
        "conflict, fp_overridden, fp_reassertion_blocked, refuted_awaiting_signoff, "
        "severity_override, validation_status "
        "FROM report_finding WHERE binding_id = %s ORDER BY finding_id",
        (result.binding_id,),
    ).fetchall()
    assert len(rows) == 2

    disposed, bare = rows
    assert disposed[:5] == (
        "FIND-001",
        "a" * 64,
        "confirmed",
        "fix_in_progress",
        "execution_proven",
    )
    assert (disposed[5], disposed[6], disposed[7], disposed[8]) == (False, True, True, False)
    assert disposed[9]["severity"] == "critical"
    assert disposed[10] == "confirmed"
    assert bare[0] == "FIND-002"
    assert all(value is None for value in bare[1:])
    conn.commit()


def test_postgres_subject_ownership_matches_sqlite(database: tuple[Any, str]) -> None:
    """GAP C on the other dialect, from the same fixture.

    is_branch_audit is INTEGER on SQLite and BOOLEAN here; the row must still
    say the same thing, and an absent flag must stay NULL on both.
    """
    conn, _ = database
    store = Store(conn)
    store.init()
    result = store.ingest("corpus-registry", sample("corpus-registry")[0], Binding())
    rows = conn.execute(
        "SELECT subject_id, tree, ownership, business_unit, product, ref_kind, "
        "is_branch_audit FROM subject_ownership WHERE binding_id = %s ORDER BY subject_id",
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
            False,
        ),
        (
            "other/example/repo@release-1.0",
            "other-findings",
            "external-bu",
            "Other Unit",
            None,
            "branch",
            True,
        ),
    ]
    conn.commit()
