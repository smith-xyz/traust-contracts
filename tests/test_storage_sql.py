"""Authored SQL execution, dependency order, profiles, and package resources."""

import json
import sqlite3
import tomllib
from pathlib import Path

from storage_samples import FAMILIES, PROJECTION_TABLES, RUN_BOUND

from traust_contracts.paths import storage_dir
from traust_contracts.v1.storage.sql import bootstrap_files, bootstrap_statements

TABLES = {
    "artifact_evidence",
    "artifact_binding",
    "traust_storage_meta",
    *PROJECTION_TABLES.values(),
}


def test_sqlite_bootstrap_statements_execute_and_reexecute() -> None:
    conn = sqlite3.connect(":memory:")
    conn.execute("PRAGMA foreign_keys = ON")
    try:
        for _ in range(2):
            conn.execute("BEGIN")
            for path in bootstrap_files("sqlite"):
                for statement in bootstrap_statements("sqlite", path):
                    conn.execute(statement)
                    assert conn.in_transaction
            conn.execute("COMMIT")
        assert conn.execute("SELECT * FROM current_binding").fetchall() == []
        assert conn.execute("SELECT * FROM findings_summary").fetchall() == []
        assert conn.execute("PRAGMA foreign_key_list(artifact_binding)").fetchall()
        for table in PROJECTION_TABLES.values():
            assert conn.execute(f"PRAGMA foreign_key_list({table})").fetchall()
    finally:
        conn.close()


def test_storage_profiles_cover_schemas_and_only_project_the_first_slice() -> None:
    document = json.loads((storage_dir() / "profiles.json").read_text())
    profiles = document["artifacts"]
    assert document["version"] == 1
    assert set(profiles) == set(FAMILIES)
    assert {
        name: profile["projection"] for name, profile in profiles.items() if "projection" in profile
    } == PROJECTION_TABLES
    assert profiles["vuln-findings"] == {
        "class": "run-bound",
        "required": ["subject_id", "run_id"],
        "projection": "finding",
    }
    assert {
        name for name, profile in profiles.items() if profile["class"] == "run-bound"
    } == RUN_BOUND
    assert profiles["triage"]["required"] == ["subject_id", "run_id"]
    assert profiles["layer"]["required"] == ["layer_id"]


def test_storage_package_resources() -> None:
    root = storage_dir()
    assert (root / "README.md").is_file()
    assert (root / "profiles.json").is_file()
    for dialect in ["postgres", "sqlite"]:
        files = bootstrap_files(dialect)
        assert [path.name for path in files[:2]] == [
            "artifact_evidence.sql",
            "artifact_binding.sql",
        ]
        schema_files = {path.stem for path in (root / dialect / "schema").glob("*.sql")}
        assert schema_files == TABLES
        for entity in TABLES - {"traust_storage_meta"}:
            assert "CREATE TABLE" in (root / dialect / "schema" / f"{entity}.sql").read_text()
        for entity in [
            "artifact_evidence",
            "artifact_binding",
            *PROJECTION_TABLES.values(),
        ]:
            assert (root / dialect / "queries" / f"{entity}.upsert.sql").is_file()
        assert {path.stem for path in (root / dialect / "views").glob("*.sql")} == {
            "binding_current",
            "findings_summary",
        }
    project = tomllib.loads((Path(__file__).parents[1] / "pyproject.toml").read_text())
    targets = project["tool"]["hatch"]["build"]["targets"]
    assert targets["wheel"]["force-include"]["storage/v1"] == "traust_contracts/storage/v1"
    assert "/tests/fixtures/storage" in targets["sdist"]["exclude"]
