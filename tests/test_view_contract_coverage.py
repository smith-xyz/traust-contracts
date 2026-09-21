"""A view must expose what its contract declares, or say why not.

The failure this catches is silent and was made three times in one
sitting: a view is authored from the fields someone happened to need,
the numbers agree with whatever else projects the same artifact, and
nobody notices that two thirds of the contract never reached SQL.

Agreement between two projections proves nothing when both drop the
same fields. `advisory_exposure` matched the legacy SQLite projection
exactly on every classification bucket while both were dropping 26 of
the 40 fields `impact-analysis.schema.json` declares -- including every
piece of evidence explaining HOW a classification was reached, which is
the entire point of an impact analysis.

So the reference is the SCHEMA. For every fan-out view, the fields the
contract declares on the item being fanned out must appear in the view,
or be listed in EXEMPT with a reason a reviewer can disagree with.
"""

from __future__ import annotations

import json
import re

import pytest

from traust_contracts.paths import schema_dir, storage_dir

#: view -> (schema file, JSON pointer to the ITEM the view fans out).
#: A pointer of () means the document root.
FAN_OUT_VIEWS: dict[str, tuple[str, tuple[str, ...]]] = {
    "advisory_exposure": ("impact-analysis.schema.json", ("repos",)),
    "validation_current": ("validation.schema.json", ("validated_findings",)),
    "threat_current": ("threat-model.schema.json", ("threats",)),
}

#: Fields a view deliberately does not carry, each with the reason.
#: A reason a reviewer can disagree with -- not "not needed yet".
EXEMPT: dict[tuple[str, str], str] = {
    ("advisory_exposure", "evidence"): ("the block itself; its members are checked individually"),
    ("validation_current", "steps"): (
        "the per-step execution log, one level below this view's grain. "
        "Its scope_reason is already surfaced as skip_reason on the "
        "projection; the rest belongs to a steps view if one is ever needed"
    ),
    ("validation_current", "source_report"): (
        "the path of the report validated, which is resolver bookkeeping "
        "rather than an outcome; the binding carries the identity"
    ),
    ("threat_current", "actor"): "exposed as `actors`, plural, on the projection",
    ("threat_current", "id"): "exposed as `threat_id`; `id` collides across models",
}


def _deref(schema: dict, node: dict) -> dict:
    return schema["$defs"][node["$ref"].split("/")[-1]] if "$ref" in node else node


def _item_properties(schema: dict, pointer: tuple[str, ...]) -> dict:
    node = schema
    for step in pointer:
        node = _deref(schema, node["properties"][step])
        if node.get("type") == "array":
            node = _deref(schema, node["items"])
    return node.get("properties", {})


def _declared(schema: dict, pointer: tuple[str, ...]) -> set[str]:
    """Every field the contract declares on the item, evidence flattened.

    A nested evidence/detail block is where the interesting fields hide,
    so it is flattened rather than treated as one opaque column -- that
    is exactly how 15 of impact-analysis's 19 evidence fields went
    missing without anyone noticing.
    """
    props = _item_properties(schema, pointer)
    names = set(props)
    for nested in ("evidence",):
        block = props.get(nested)
        if isinstance(block, dict):
            names |= set(_deref(schema, block).get("properties", {}))
    return names


@pytest.mark.parametrize("view", sorted(FAN_OUT_VIEWS))
def test_view_exposes_what_its_contract_declares(view: str) -> None:
    schema_file, pointer = FAN_OUT_VIEWS[view]
    schema = json.loads((schema_dir() / schema_file).read_text(encoding="utf-8"))
    sql = (storage_dir() / "sqlite" / "views" / f"{view}.sql").read_text(encoding="utf-8")

    declared = _declared(schema, pointer)
    missing = {name for name in declared if not re.search(rf"\b{re.escape(name)}\b", sql)}
    unexplained = sorted(name for name in missing if (view, name) not in EXEMPT)
    assert not unexplained, (
        f"{view} drops {len(unexplained)} field(s) {schema_file} declares: "
        f"{', '.join(unexplained)}. Expose them, or add an EXEMPT entry "
        f"with a reason. A field the contract declares and no view carries "
        f"is unreachable from SQL no matter what is loaded."
    )


def test_every_exemption_is_still_needed() -> None:
    """An exemption for a field a view now carries hides the next gap."""
    stale = []
    for (view, name), _reason in EXEMPT.items():
        schema_file, pointer = FAN_OUT_VIEWS[view]
        schema = json.loads((schema_dir() / schema_file).read_text(encoding="utf-8"))
        if name not in _declared(schema, pointer):
            stale.append(f"{view}:{name} (no longer declared by {schema_file})")
    assert not stale, f"stale exemptions: {stale}"


def test_both_dialects_expose_the_same_fields() -> None:
    """Parity at the field level, not just the view-name level.

    A field added to one dialect and forgotten in the other is a view
    that answers differently depending on the adopter's database.
    """
    for view in FAN_OUT_VIEWS:
        names = {}
        for dialect in ("sqlite", "postgres"):
            sql = (storage_dir() / dialect / "views" / f"{view}.sql").read_text(encoding="utf-8")
            # select-list aliases only: `AS name,` or `AS name` at a line
            # end. `AS entry(value)` is a LATERAL table alias, not a column.
            names[dialect] = set(re.findall(r"\bAS ([a-z_][a-z0-9_]*)\s*(?:,|$)", sql, re.M))
        assert names["sqlite"] == names["postgres"], (
            f"{view}: dialects expose different columns — "
            f"sqlite-only {sorted(names['sqlite'] - names['postgres'])}, "
            f"postgres-only {sorted(names['postgres'] - names['sqlite'])}"
        )
