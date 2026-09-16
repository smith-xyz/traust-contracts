"""Read authored SQL in deterministic table-then-view bootstrap order."""

import sqlite3
from collections.abc import Iterator
from functools import cache
from pathlib import Path
from typing import Literal

from traust_contracts.paths import storage_dir

Dialect = Literal["postgres", "sqlite"]
CONTRACT_VERSION = "v1"
REVISION = 2


@cache
def query(dialect: Dialect, filename: str) -> str:
    return (storage_dir() / dialect / "queries" / filename).read_text(encoding="utf-8")


def bootstrap_files(dialect: Dialect) -> list[Path]:
    """Return dependency-ordered tables followed by deterministic views."""
    root = storage_dir() / dialect
    schema = {path.name: path for path in (root / "schema").glob("*.sql")}
    first = [schema.pop(name) for name in ("artifact_evidence.sql", "artifact_binding.sql")]
    return [*first, *sorted(schema.values()), *sorted((root / "views").glob("*.sql"))]


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
