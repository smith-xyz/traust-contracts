"""Read authored Ledger SQL in deterministic bootstrap order."""

from __future__ import annotations

from pathlib import Path

from traust_contracts.paths import ledger_dir
from traust_contracts.v1.sql import Dialect
from traust_contracts.v1.sql import bootstrap_files as _bootstrap_files
from traust_contracts.v1.sql import bootstrap_statements as bootstrap_statements

CONTRACT_VERSION = "v1"
REVISION = 1
POSTGRES_SCHEMA = "traust_ledger"
# Foreign-key dependency order; this is the complete v1 table inventory.
TABLE_ORDER: tuple[str, ...] = (
    "schema_revision",
    "layers",
    "events",
    "materialized_findings",
)


def bootstrap_files(dialect: Dialect, version: str = "v1") -> list[Path]:
    """Return the namespace followed by authored tables in dependency order."""
    return _bootstrap_files(
        ledger_dir(version), dialect, first_tables=TABLE_ORDER, exact_tables=True
    )
