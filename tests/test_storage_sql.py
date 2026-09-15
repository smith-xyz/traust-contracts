"""Authored SQL execution and package-resource checks (no rendering or goldens)."""

import sqlite3
import tomllib
from pathlib import Path

from storage_samples import FAMILIES, PROJECTION_TABLES

from traust_contracts.paths import storage_dir
from traust_contracts.v1.storage.sql import bootstrap_files, bootstrap_statements


def test_sqlite_bootstrap_statements_execute_and_reexecute() -> None:
    conn = sqlite3.connect(":memory:")
    try:
        for _ in range(2):
            conn.execute("BEGIN")
            for path in bootstrap_files("sqlite"):
                for statement in bootstrap_statements("sqlite", path):
                    conn.execute(statement)
                    assert conn.in_transaction
            conn.execute("COMMIT")
        assert conn.execute("SELECT * FROM compliance_dashboard").fetchall() == []
        for table in ["artifact", "finding", "layer_metadata", "triage_verdict"]:
            assert conn.execute(f"PRAGMA foreign_key_list({table})").fetchall() == []
    finally:
        conn.close()


def test_storage_package_resources() -> None:
    root = storage_dir()
    assert (root / "README.md").is_file()
    assert not list(root.rglob("*.json"))
    for dialect in ["postgres", "sqlite"]:
        assert bootstrap_files(dialect)
        schema_files = sorted((root / dialect / "schema").glob("*.sql"))
        projection_tables = sorted(set(PROJECTION_TABLES.values()))
        assert [path.stem for path in schema_files] == sorted(
            ["artifact", "traust_storage_meta", *projection_tables]
        )
        assert set(PROJECTION_TABLES) == set(FAMILIES)
        for entity in ["artifact", *projection_tables]:
            sql = (root / dialect / "schema" / f"{entity}.sql").read_text()
            assert "CREATE TABLE" in sql
            assert (root / dialect / "queries" / f"{entity}.upsert.sql").is_file()
        assert len(list((root / dialect / "views").glob("compliance_dashboard.sql"))) == 1
    project = tomllib.loads((Path(__file__).parents[1] / "pyproject.toml").read_text())
    targets = project["tool"]["hatch"]["build"]["targets"]
    assert targets["wheel"]["force-include"]["storage/v1"] == "traust_contracts/storage/v1"
    assert "/tests/fixtures/storage" in targets["sdist"]["exclude"]
