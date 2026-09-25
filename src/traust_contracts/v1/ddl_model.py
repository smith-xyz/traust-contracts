"""Parse authored table DDL into a dialect-merged model and render it as Mermaid.

Domain-specific generators (storage, ledger, ...) supply the table root and any
domain classification (artifact profiles, projections, views); this module only
knows about tables, columns, primary keys, and foreign keys.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path

COLUMN = re.compile(r"^\s{4}([a-z][a-z0-9_]*)\s+([A-Z]+(?:\s+PRECISION)?)(.*?),?\s*$")
PK = re.compile(r"PRIMARY KEY \(([^)]*)\)")
FK = re.compile(r"FOREIGN KEY \(([^)]*)\)\s*REFERENCES\s+(?:[a-z_]+\.)?([a-z_]+)\(([^)]*)\)", re.S)
INLINE_FK = re.compile(r"REFERENCES (?:[a-z_]+\.)?([a-z_]+)\(([^)]*)\)")


@dataclass
class TableModel:
    pk: set[str] = field(default_factory=set)
    fks: list[tuple[str, list[str]]] = field(default_factory=list)
    types: dict[str, dict[str, tuple[str, bool]]] = field(default_factory=dict)


def _uncommented(sql: str) -> str:
    return "\n".join(line.split("--")[0] for line in sql.splitlines())


def parse_table(sql: str) -> dict:
    sql = _uncommented(sql)
    body = sql[sql.index("(") + 1 :]
    cols, pk, fks = [], set(), []
    m = PK.search(body)
    if m:
        pk = {c.strip() for c in m.group(1).split(",")}
    for m in FK.finditer(body):
        fks.append((m.group(2), [c.strip() for c in m.group(1).split(",")]))
    for line in body.splitlines():
        cm = COLUMN.match(line)
        if not cm or cm.group(1) in ("primary", "foreign"):
            continue
        name, typ, rest = cm.group(1), cm.group(2), cm.group(3)
        notnull = "NOT NULL" in rest
        ref = INLINE_FK.search(rest)
        if ref:
            fks.append((ref.group(1), [name]))
        cols.append((name, typ, notnull))
    return {"columns": cols, "pk": pk, "fks": fks}


def load_tables(
    schema_root: Path, dialects: tuple[str, ...] = ("sqlite", "postgres")
) -> dict[str, TableModel]:
    """Merge per-dialect schema/*.sql into one dialect-tagged model per table."""
    tables: dict[str, TableModel] = {}
    for dialect in dialects:
        for path in sorted((schema_root / dialect / "schema").glob("*.sql")):
            parsed = parse_table(path.read_text())
            entry = tables.setdefault(path.stem, TableModel(pk=parsed["pk"], fks=parsed["fks"]))
            for name, typ, notnull in parsed["columns"]:
                entry.types.setdefault(name, {})[dialect] = (typ, notnull)
    return tables


def type_label(types: dict[str, tuple[str, bool]]) -> str:
    s, p = types.get("sqlite"), types.get("postgres")
    if s and p and s[0] != p[0]:
        return f"{s[0]}|{p[0]}"
    return (s or p)[0]


def render_class(name: str, table: TableModel, note: str | None = None) -> list[str]:
    lines = [f"  class {name} {{"]
    if note:
        lines.append(f"    «{note}»")
    for col, types in table.types.items():
        marker = "+" if col in table.pk else " "
        lines.append(f"    {marker}{type_label(types)} {col}")
    lines.append("  }")
    return lines


def render_diagram(
    names: list[str],
    tables: dict[str, TableModel],
    notes: dict[str, str] | None = None,
    direction: str = "LR",
) -> str:
    out = ["```mermaid", "classDiagram", f"  direction {direction}"]
    for n in names:
        out += render_class(n, tables[n], (notes or {}).get(n))
    for n in names:
        for target, cols in tables[n].fks:
            out.append(f"  {target} <-- {n} : {','.join(cols)}")
    out.append("```")
    return "\n".join(out)
