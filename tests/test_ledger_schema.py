"""SQL-first Ledger v1 inventory, execution and metadata gates."""

from __future__ import annotations

import contextlib
import re
import sqlite3
import tomllib
from pathlib import Path

import pytest

from traust_contracts.paths import ledger_dir, storage_dir
from traust_contracts.v1.ledger import (
    CONTRACT_VERSION,
    POSTGRES_SCHEMA,
    REVISION,
    TABLE_ORDER,
    bootstrap_files,
    bootstrap_statements,
)

ROOT = Path(__file__).parents[1]
TABLES = ("schema_revision", "layers", "events", "materialized_findings")


@pytest.mark.parametrize("dialect", ["postgres", "sqlite"])
def test_exact_sql_inventory_and_bootstrap_order(dialect: str) -> None:
    root = ledger_dir() / dialect
    namespace = [root / "namespace.sql"] if dialect == "postgres" else []
    expected = [*namespace, *(root / "schema" / f"{name}.sql" for name in TABLES)]
    assert CONTRACT_VERSION == "v1"
    assert REVISION == 1
    assert POSTGRES_SCHEMA == "traust_ledger"
    assert TABLE_ORDER == TABLES
    assert bootstrap_files(dialect) == expected
    assert {p.name for p in (root / "schema").glob("*.sql")} == {f"{name}.sql" for name in TABLES}
    assert {p.relative_to(root).as_posix() for p in root.rglob("*.sql")} == {
        *(p.relative_to(root).as_posix() for p in expected),
    }
    assert not (ledger_dir() / "manifest.json").exists()
    assert not (ledger_dir() / "manifest.schema.json").exists()
    assert not (root / "queries").exists()


def test_sqlite_bootstrap_metadata_and_relations() -> None:
    with contextlib.closing(sqlite3.connect(":memory:")) as connection:
        connection.execute("PRAGMA foreign_keys = ON")
        for path in bootstrap_files("sqlite"):
            for statement in bootstrap_statements("sqlite", path):
                connection.execute(statement)
        relations = {
            name
            for (name,) in connection.execute(
                "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'"
            )
        }
        assert relations == set(TABLES)
        connection.execute(
            "INSERT INTO schema_revision VALUES (:id, :contract_version, :revision, :applied_at)",
            {
                "id": 1,
                "contract_version": CONTRACT_VERSION,
                "revision": REVISION,
                "applied_at": "2026-01-01",
            },
        )
        assert connection.execute(
            "SELECT contract_version, revision FROM schema_revision"
        ).fetchone() == ("v1", 1)
        assert connection.execute("SELECT id, applied_at FROM schema_revision").fetchone() == (
            1,
            "2026-01-01",
        )
        with pytest.raises(sqlite3.IntegrityError):
            connection.execute("INSERT INTO schema_revision VALUES (2, 'v1', 1, '2026-01-01')")
        with pytest.raises(sqlite3.IntegrityError):
            connection.execute(
                "INSERT INTO events (layer_id, seq, event_id, event_payload) "
                "VALUES ('missing', 0, 'event', x'00')"
            )


def test_sqlite_append_only_guards() -> None:
    """Verify that bootstrapped schema installs append-only triggers."""
    with contextlib.closing(sqlite3.connect(":memory:")) as conn:
        conn.execute("PRAGMA foreign_keys = ON")
        for path in bootstrap_files("sqlite"):
            for statement in bootstrap_statements("sqlite", path):
                conn.execute(statement)
        # verify triggers exist
        triggers = {
            name
            for (name,) in conn.execute("SELECT name FROM sqlite_master WHERE type = 'trigger'")
        }
        assert "events_reject_update" in triggers
        assert "events_reject_delete" in triggers
        assert "events_validate_append" in triggers
        assert "layers_reject_delete" in triggers
        # insert valid data
        conn.execute(
            "INSERT INTO layers (layer_id, metadata_payload, needs_review_payload, "
            "extensions_payload, root_keys_payload) VALUES ('L1', x'00', x'00', x'00', x'00')"
        )
        conn.execute(
            "INSERT INTO events (layer_id, seq, event_id, event_payload) "
            "VALUES ('L1', 0, 'e0', x'AA')"
        )
        # UPDATE on events must fail
        with pytest.raises(sqlite3.IntegrityError, match="append-only"):
            conn.execute("UPDATE events SET event_payload = x'BB' WHERE event_id = 'e0'")
        # DELETE on events must fail
        with pytest.raises(sqlite3.IntegrityError, match="append-only"):
            conn.execute("DELETE FROM events WHERE event_id = 'e0'")
        # DELETE on layers must fail
        with pytest.raises(sqlite3.IntegrityError, match="cannot be deleted"):
            conn.execute("DELETE FROM layers WHERE layer_id = 'L1'")
        # out-of-order seq must fail
        with pytest.raises(sqlite3.IntegrityError, match="append at the next sequence"):
            conn.execute(
                "INSERT INTO events (layer_id, seq, event_id, event_payload) "
                "VALUES ('L1', 5, 'e5', x'CC')"
            )


def test_postgres_sql_qualified_and_metadata_shape() -> None:
    root = ledger_dir() / "postgres"
    ns = (root / "namespace.sql").read_text()
    assert "CREATE SCHEMA IF NOT EXISTS traust_ledger;" in ns
    assert "reject_authoritative_mutation" in ns
    assert "validate_event_append" in ns
    for name in TABLES:
        sql = (root / "schema" / f"{name}.sql").read_text()
        assert re.findall(r"CREATE TABLE ([\w.]+) \(", sql) == [f"traust_ledger.{name}"]
    assert "REFERENCES traust_ledger.layers" in (root / "schema" / "events.sql").read_text()
    revision = (root / "schema" / "schema_revision.sql").read_text()
    assert "id INTEGER PRIMARY KEY CHECK (id = 1)" in revision
    assert "contract_version TEXT NOT NULL" in revision
    assert "revision INTEGER NOT NULL" in revision
    assert "applied_at TIMESTAMPTZ NOT NULL" in revision


def test_packaging_and_baseline_independence() -> None:
    includes = tomllib.loads((ROOT / "pyproject.toml").read_text())["tool"]["hatch"]["build"][
        "targets"
    ]["wheel"]["force-include"]
    assert includes["ledger/v1"] == "traust_contracts/ledger/v1"
    assert includes["storage/v1"] == "traust_contracts/storage/v1"
    assert not any(
        "traust_ledger." in p.read_text().lower() or "schema_revision" in p.read_text().lower()
        for p in storage_dir().rglob("*.sql")
    )
