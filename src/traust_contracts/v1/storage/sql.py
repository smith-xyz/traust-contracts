"""Read authored SQL in deterministic table-then-view bootstrap order."""

import sqlite3
from collections.abc import Iterator
from functools import cache
from pathlib import Path
from typing import Literal

from traust_contracts.paths import storage_dir

Dialect = Literal["postgres", "sqlite"]
CONTRACT_VERSION = "v1"
#: 3 (2026-09-19): ownership_current. Views are CREATE ... IF NOT EXISTS,
#: so an existing store keeps the definitions it was built with -- and the
#: pre-3 ones join subject_ownership raw, which double-counts every finding
#: once per corpus-registry import. Failing closed here is deliberate: a
#: store on the old revision may ALREADY be serving inflated numbers.
REVISION = 3


@cache
def query(dialect: Dialect, filename: str) -> str:
    return (storage_dir() / dialect / "queries" / filename).read_text(encoding="utf-8")


#: Views that other views select FROM, in the order they must be created.
#: Alphabetical order is not dependency order -- `current_finding` sorts
#: before `report_current` but selects from it, and PostgreSQL resolves a
#: view's references at CREATE time, so the glob order alone fails there
#: while silently succeeding on SQLite.
VIEW_ORDER: tuple[str, ...] = (
    "binding_current.sql",
    "report_current.sql",
    "ownership_current.sql",
    "current_finding.sql",
)


def bootstrap_files(dialect: Dialect) -> list[Path]:
    """Return dependency-ordered tables followed by dependency-ordered views."""
    root = storage_dir() / dialect
    schema = {path.name: path for path in (root / "schema").glob("*.sql")}
    first = [schema.pop(name) for name in ("artifact_evidence.sql", "artifact_binding.sql")]
    namespace = [root / "namespace.sql"] if dialect == "postgres" else []
    views = {path.name: path for path in (root / "views").glob("*.sql")}
    ordered = [views.pop(name) for name in VIEW_ORDER if name in views]
    return [
        *namespace,
        *first,
        *sorted(schema.values()),
        *ordered,
        *sorted(views.values()),
    ]


def bootstrap_statements(dialect: Dialect, path: Path) -> Iterator[str]:
    """Yield driver-safe statements while preserving authored file boundaries."""
    sql = path.read_text(encoding="utf-8")
    if dialect == "postgres":
        yield sql
        return
    statement = ""
    for line in sql.splitlines(keepends=True):
        statement += line
        if sqlite3.complete_statement(statement):
            yield statement
            statement = ""
    if statement.strip():
        raise ValueError(f"incomplete SQLite statement in {path.name}")
