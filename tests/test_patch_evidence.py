"""The patch-evidence block on remediation reports (ToB plan item 5a, option B).

The load-bearing rule is the conditional: an item may claim `proves` or
`fails_to_prove` only if it recorded what was observed on BOTH revisions. That
is what stops an unexecuted check from being filed as evidence, and it is the
reason this block exists rather than another `checks[]` entry (checks carry a
pass/fail with no before/after at all).
"""

import json
from pathlib import Path

import pytest
from jsonschema import Draft202012Validator
from referencing import Registry, Resource

REPO_ROOT = Path(__file__).parent.parent
SCHEMA_DIR = REPO_ROOT / "schemas" / "v1"


def _validator():
    resources = {}
    for sf in sorted(SCHEMA_DIR.glob("*.schema.json")):
        doc = json.loads(sf.read_text(encoding="utf-8"))
        resources[doc.get("$id", sf.name)] = Resource.from_contents(doc)
    schema = json.loads((SCHEMA_DIR / "remediation.schema.json").read_text(encoding="utf-8"))
    return Draft202012Validator(
        {"$ref": "#/$defs/patch_evidence", "$defs": schema["$defs"]},
        registry=Registry(resources=resources),
    )


PROVEN = {
    "kind": "mutation",
    "outcome": "proves",
    "base_observation": "mutant 7 survives at oauth.go:212",
    "patched_observation": "mutant 7 killed by TestTokenReviewRejectsAnonymous",
    "tool": "mewt 4.0.0",
    "command": "mewt run --language go ./pkg/oauth",
    "deterministic_steps": "ran",
}


def test_evidence_with_both_observations_is_valid():
    assert not list(_validator().iter_errors(PROVEN))


@pytest.mark.parametrize("missing", ["base_observation", "patched_observation"])
def test_proves_requires_both_observations(missing):
    """The rule: no claim of proof without both sides of the comparison."""
    item = {k: v for k, v in PROVEN.items() if k != missing}
    errors = list(_validator().iter_errors(item))
    assert errors, f"dropping {missing} must invalidate a 'proves' claim"


def test_fails_to_prove_also_requires_both_observations():
    item = {k: v for k, v in PROVEN.items() if k != "base_observation"}
    item["outcome"] = "fails_to_prove"
    assert list(_validator().iter_errors(item))


def test_not_attempted_needs_no_observations_but_needs_a_reason():
    ok = {"kind": "property", "outcome": "not_attempted: no property harness for this package"}
    assert not list(_validator().iter_errors(ok))
    bare = {"kind": "property", "outcome": "not_attempted"}
    assert list(_validator().iter_errors(bare)), "a bare not_attempted must carry its reason"


def test_outcome_vocabulary_is_closed():
    for bad in ("passed", "pass", "proven", "PROVES", "skipped"):
        assert list(_validator().iter_errors({"kind": "regression", "outcome": bad})), bad


def test_kind_vocabulary_is_closed():
    assert list(_validator().iter_errors({"kind": "behaviour", "outcome": "not_attempted: x"}))


def test_deterministic_steps_carries_a_reason_when_skipped():
    item = dict(PROVEN, deterministic_steps="skipped")
    assert list(_validator().iter_errors(item))
    ok = dict(PROVEN, deterministic_steps="skipped: no toolchain")
    assert not list(_validator().iter_errors(ok))


def test_evidence_is_optional_and_plural_on_the_report():
    """Additive: existing reports stay valid, and several kinds can coexist."""
    schema = json.loads((SCHEMA_DIR / "remediation.schema.json").read_text(encoding="utf-8"))
    assert "evidence" not in schema["required"]
    assert schema["properties"]["evidence"]["type"] == "array"


def test_revalidation_remains_the_live_validation_channel():
    """Option B keeps the two separate; mutation verdicts never become validation verdicts."""
    schema = json.loads((SCHEMA_DIR / "remediation.schema.json").read_text(encoding="utf-8"))
    methods = schema["$defs"]["revalidation"]["properties"]["method"]["enum"]
    kinds = schema["$defs"]["patch_evidence_kind"]["enum"]
    assert not set(methods) & set(kinds)
