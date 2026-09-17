"""Authored SQL execution, dependency order, profiles, and package resources."""

import json
import re
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
POSTGRES_SCHEMA = "traust_storage"
POSTGRES_RELATIONS = {*TABLES, "current_binding", "findings_summary"}
POSTGRES_RELATION_REFERENCE = re.compile(
    r"(?:CREATE TABLE IF NOT EXISTS|CREATE OR REPLACE VIEW|INSERT INTO|REFERENCES|FROM|JOIN|"
    r"UPDATE|ALTER TABLE|DELETE FROM)\s+([a-z_][a-z0-9_.]*)",
    re.IGNORECASE,
)
POSTGRES_INDEX_REFERENCE = re.compile(
    r"CREATE (?:UNIQUE )?INDEX IF NOT EXISTS [a-z_][a-z0-9_]*\s+ON\s+"
    r"([a-z_][a-z0-9_.]*)",
    re.IGNORECASE,
)


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


def test_postgres_relations_use_the_storage_schema() -> None:
    root = storage_dir() / "postgres"
    assert (root / "namespace.sql").read_text().strip() == (
        "CREATE SCHEMA IF NOT EXISTS traust_storage;"
    )
    for path in root.rglob("*.sql"):
        if path.name == "namespace.sql":
            continue
        sql = path.read_text()
        references = [
            *POSTGRES_RELATION_REFERENCE.findall(sql),
            *POSTGRES_INDEX_REFERENCE.findall(sql),
        ]
        for relation in references:
            unqualified = relation.rsplit(".", maxsplit=1)[-1]
            if unqualified in POSTGRES_RELATIONS:
                assert relation == f"{POSTGRES_SCHEMA}.{unqualified}", (
                    f"{path.relative_to(root)} contains unqualified relation {relation}"
                )


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
        expected_prefix = ["artifact_evidence.sql", "artifact_binding.sql"]
        if dialect == "postgres":
            expected_prefix.insert(0, "namespace.sql")
        assert [path.name for path in files[: len(expected_prefix)]] == expected_prefix
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
