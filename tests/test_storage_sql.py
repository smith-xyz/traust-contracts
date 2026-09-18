"""Authored SQL execution, dependency order, profiles, and package resources."""

import json
import re
import sqlite3
import tomllib
from pathlib import Path

from storage_samples import (
    FAMILIES,
    PROJECTION_TABLES,
    RUN_BOUND,
    SECONDARY_PROJECTION_TABLES,
)

from traust_contracts.paths import storage_dir
from traust_contracts.v1.storage.sql import bootstrap_files, bootstrap_statements

TABLES = {
    "artifact_evidence",
    "artifact_binding",
    "traust_storage_meta",
    *PROJECTION_TABLES.values(),
    *SECONDARY_PROJECTION_TABLES.values(),
}
POSTGRES_SCHEMA = "traust_storage"
POSTGRES_RELATIONS = {*TABLES, "current_binding", "findings_summary", "report_current"}
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
DIALECTS = ("sqlite", "postgres")
VIEW_DECLARATION = re.compile(
    r"CREATE (?:OR REPLACE )?VIEW (?:IF NOT EXISTS )?(?:traust_storage\.)?([a-z_][a-z0-9_]*)",
    re.IGNORECASE,
)
COLUMN_ALIAS = re.compile(r"\bAS\s+([a-z_][a-z0-9_]*)\s*$", re.IGNORECASE)
SELECT_KEYWORD = re.compile(r"\bSELECT\b", re.IGNORECASE)


def _uncommented(sql: str) -> str:
    """Drop line comments. No storage SQL puts `--` inside a string literal."""
    return "\n".join(line.split("--")[0] for line in sql.splitlines())


def _top_level_projection(sql: str) -> str:
    """The text between a view's own SELECT and its own FROM, ignoring subqueries."""
    body = _uncommented(sql)
    select = SELECT_KEYWORD.search(body)
    assert select, "view declares no SELECT"
    depth = 0
    index = select.end()
    while index < len(body):
        character = body[index]
        if character == "(":
            depth += 1
        elif character == ")":
            depth -= 1
        elif (
            depth == 0
            and body[index : index + 4].upper() == "FROM"
            and not body[index - 1].isalnum()
            and not body[index + 4].isalnum()
        ):
            return body[select.end() : index]
        index += 1
    raise AssertionError("view declares no top-level FROM")


def _output_columns(sql: str) -> list[str]:
    """Output column names of a view: its alias, else the bare column, else `*`.

    Normalising to the *output* name is the point — the two dialects reach
    `repo` through different table aliases (`layer` vs `layer_metadata`), which
    a consumer never sees and must not be gated on.
    """
    items: list[str] = []
    current = ""
    depth = 0
    for character in _top_level_projection(sql):
        if character == "(":
            depth += 1
        elif character == ")":
            depth -= 1
        if character == "," and depth == 0:
            items.append(current)
            current = ""
        else:
            current += character
    items.append(current)
    columns = []
    for item in items:
        collapsed = " ".join(item.split())
        alias = COLUMN_ALIAS.search(collapsed)
        columns.append(alias.group(1) if alias else collapsed.rsplit(".", maxsplit=1)[-1])
    return columns


def _declared_views(dialect: str) -> dict[str, list[str]]:
    views = {}
    for path in sorted((storage_dir() / dialect / "views").glob("*.sql")):
        sql = path.read_text()
        declaration = VIEW_DECLARATION.search(sql)
        assert declaration, f"{path.name} declares no view"
        views[declaration.group(1)] = _output_columns(sql)
    return views


def test_view_names_are_read_from_the_sql_not_the_filename() -> None:
    """`views/binding_current.sql` declares a view called `current_binding`.

    Every parity check below keys on the declared name for that reason; one
    keyed on filenames would assert against an identifier no consumer can use.
    """
    for dialect in DIALECTS:
        names = set(_declared_views(dialect))
        assert names == {"current_binding", "findings_summary", "report_current"}, dialect
        assert "binding_current" in {
            path.stem for path in (storage_dir() / dialect / "views").glob("*.sql")
        }


def test_view_output_columns_are_identical_across_dialects() -> None:
    """A dashboard is only backend-independent if its view returns one shape."""
    sqlite_views, postgres_views = (_declared_views(dialect) for dialect in DIALECTS)
    assert sorted(sqlite_views) == sorted(postgres_views)
    for name, columns in sqlite_views.items():
        assert columns == postgres_views[name], (
            f"view {name} projects {columns} on sqlite but {postgres_views[name]} on postgres"
        )
    assert sqlite_views["findings_summary"] == [
        "scope_id",
        "subject_id",
        "run_id",
        "layer_id",
        "repo",
        "severity",
        "verdict",
        "finding_count",
    ]
    assert sqlite_views["current_binding"] == ["*"]


def test_read_queries_exist_in_both_dialects_and_target_views() -> None:
    """The per-dialect tax on a new dashboard aggregate is two `.list.sql` files.

    `.upsert.sql` parity was already gated; a read query landing on one dialect
    only was not, which is the shape that breaks a database adopter silently.
    """
    per_dialect = {
        dialect: {path.name for path in (storage_dir() / dialect / "queries").glob("*.list.sql")}
        for dialect in DIALECTS
    }
    assert per_dialect["sqlite"], "no read queries found"
    assert per_dialect["sqlite"] == per_dialect["postgres"], (
        f"read queries differ: {per_dialect['sqlite'] ^ per_dialect['postgres']}"
    )
    views = set(_declared_views("sqlite"))
    for name in per_dialect["sqlite"]:
        assert name.removesuffix(".list.sql") in views, (
            f"{name} reads something other than a declared view"
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
            "report_current",
        }
    project = tomllib.loads((Path(__file__).parents[1] / "pyproject.toml").read_text())
    targets = project["tool"]["hatch"]["build"]["targets"]
    assert targets["wheel"]["force-include"]["storage/v1"] == "traust_contracts/storage/v1"
    assert "/tests/fixtures/storage" in targets["sdist"]["exclude"]
