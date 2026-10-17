"""Review-surface coverage beyond the audit: scans, out_of_scope, threat-model tags.

A vuln-scan or verification run records the same six-surface record as the
audit (report.schema.json#/$defs/scan_review_surface_coverage). A scan has no
negative_results, so a negative entry carries its evidence in `note`; the
cumulative builder merges the record into the repo's cumulative report. A
diff-scoped scan answers an untouched surface `out_of_scope`. Threat models
tag threats and entry points with `review_surfaces`.
"""

from __future__ import annotations

import json
import sqlite3

import pytest
from jsonschema import Draft202012Validator
from referencing import Registry, Resource
from storage_samples import sample

from traust_contracts.paths import enum_dir, schema_dir
from traust_contracts.v1.storage import Binding, Store

SURFACES = json.loads((enum_dir() / "review-surface.json").read_text(encoding="utf-8"))["values"]
STATUSES = json.loads((enum_dir() / "review-surface-status.json").read_text(encoding="utf-8"))[
    "values"
]


def _schema(name: str) -> dict:
    return json.loads((schema_dir() / f"{name}.schema.json").read_text(encoding="utf-8"))


def _validator(name: str, pointer: str) -> Draft202012Validator:
    resources = {}
    for path in sorted(schema_dir().glob("*.schema.json")):
        document = json.loads(path.read_text(encoding="utf-8"))
        resources[document["$id"]] = Resource.from_contents(document)
    return Draft202012Validator(
        {"$ref": f"{_schema(name)['$id']}#{pointer}"},
        registry=Registry().with_resources(resources.items()),
    )


def _errors(name: str, pointer: str, value) -> list[str]:
    return [e.message for e in _validator(name, pointer).iter_errors(value)]


def _scan_record() -> dict:
    record = {s: {"status": "out_of_scope", "note": "the diff does not touch it"} for s in SURFACES}
    record["credential-acceptance"] = {"status": "finding", "finding_ids": ["VS-001"]}
    record["outbound-fetch"] = {"status": "negative", "note": "2 new fetch sites, both guarded"}
    return record


def test_out_of_scope_is_a_status():
    assert STATUSES[-1] == "out_of_scope"
    entry = _schema("report")["$defs"]["review_surface_entry"]
    assert entry["properties"]["status"]["enum"] == STATUSES


def test_the_scan_record_pins_the_same_surfaces():
    scan = _schema("report")["$defs"]["scan_review_surface_coverage"]
    assert scan["propertyNames"]["enum"] == SURFACES
    assert scan["required"] == SURFACES


@pytest.mark.parametrize("name", ["verification", "vuln-findings"])
def test_both_scans_declare_the_record(name):
    prop = _schema(name)["properties"]["review_surface_coverage"]
    assert prop["$ref"] == "report.schema.json#/$defs/scan_review_surface_coverage"
    assert "review_surface_coverage" not in _schema(name).get("required", [])


@pytest.mark.parametrize("name", ["verification", "vuln-findings"])
def test_a_complete_scan_record_validates(name):
    assert _errors(name, "/properties/review_surface_coverage", _scan_record()) == []


@pytest.mark.parametrize(
    ("surface", "entry", "why"),
    [
        ("outbound-fetch", {"status": "negative"}, "a scan's negative needs a note"),
        ("outbound-fetch", {"status": "negative", "note": ""}, "an empty note"),
        ("security-flags", {"status": "out_of_scope"}, "out_of_scope needs a note"),
        ("security-flags", {"status": "finding"}, "finding needs finding_ids"),
    ],
)
def test_malformed_scan_entries_fail(surface, entry, why):
    record = _scan_record()
    record[surface] = entry
    assert _errors("vuln-findings", "/properties/review_surface_coverage", record), why


def test_a_scan_record_must_answer_every_surface():
    record = _scan_record()
    record.pop("scope-enforcement")
    assert _errors("verification", "/properties/review_surface_coverage", record)


def test_an_audit_may_use_out_of_scope_with_a_note():
    record = {s: {"status": "negative"} for s in SURFACES}
    record["security-flags"] = {"status": "out_of_scope", "note": "scoped audit"}
    assert _errors("report", "/properties/review_surface_coverage", record) == []
    record["security-flags"] = {"status": "out_of_scope"}
    assert _errors("report", "/properties/review_surface_coverage", record)


@pytest.mark.parametrize(
    "pointer", ["/$defs/threat", "/$defs/entry_point", "/$defs/deprioritized_threat"]
)
def test_threat_model_tags(pointer):
    model = json.loads(sample("threat-model")[0])
    entry_point = {
        "entry_point": "HTTP API",
        "description": "public REST endpoints",
        "trust_boundary": "internet -> service",
        "reachable_assets": "tokens",
    }
    deprioritized = {"threat": "physical access to the host", "reason": "out of scope"}
    base = {
        "/$defs/threat": model["threats"][0],
        "/$defs/entry_point": entry_point,
        "/$defs/deprioritized_threat": deprioritized,
    }[pointer]
    assert _errors("threat-model", pointer, base) == []
    assert _errors("threat-model", pointer, {**base, "review_surfaces": SURFACES[:2]}) == []
    assert _errors("threat-model", pointer, {**base, "review_surfaces": ["made-up"]})
    assert _errors("threat-model", pointer, {**base, "review_surfaces": [SURFACES[0]] * 2})


def _store() -> tuple[sqlite3.Connection, Store]:
    conn = sqlite3.connect(":memory:")
    store = Store(conn)
    store.init()
    return conn, store


def test_ingest_stores_a_verification_record():
    conn, store = _store()
    payload, _ = sample("verification")
    document = json.loads(payload)
    document["review_surface_coverage"] = _scan_record()
    result = store.ingest(
        "verification",
        json.dumps(document).encode(),
        Binding("local", "sci:inventory-item:42", "sci:scan-result:7", None, None),
    )
    (stored,) = conn.execute(
        "SELECT review_surface_coverage FROM verification WHERE binding_id = ?",
        (result.binding_id,),
    ).fetchone()
    assert json.loads(stored) == _scan_record()


def test_ingest_stores_threat_tags_and_the_view_exposes_them():
    conn, store = _store()
    payload, _ = sample("threat-model")
    document = json.loads(payload)
    for threat in document["threats"]:
        threat["review_surfaces"] = ["scope-enforcement"]
    store.ingest(
        "threat-model",
        json.dumps(document).encode(),
        Binding(subject_id="findings/example/repo", run_id="r1"),
    )
    stored = conn.execute("SELECT review_surfaces FROM threat").fetchall()
    assert stored and all(json.loads(row[0]) == ["scope-enforcement"] for row in stored)
    viewed = conn.execute("SELECT review_surfaces FROM threat_current").fetchall()
    assert viewed == stored


COVERAGE_DIFF = {
    "changed_files_covered": ["src/app.py"],
    "callers_covered": ["src/views.py"],
    "refused_or_skipped": ["README.md: not first-party code"],
    "baseline_report": "findings/org/repo/repo-security-audit.json",
    "anchor": "f3ee255b833ec8da7946395b6cfccc219edd6bfb",
    "resolution_source": "override",
}
COVERAGE_DIFF_POINTER = "/$defs/metadata/properties/additional/properties/coverage_diff"


def test_the_diff_stamp_validates():
    assert _errors("vuln-findings", COVERAGE_DIFF_POINTER, COVERAGE_DIFF) == []


@pytest.mark.parametrize(
    ("mutate", "why"),
    [
        (lambda d: d.pop("anchor"), "a required key is missing"),
        (lambda d: d.__setitem__("callers_covered", "src/views.py"), "a list written as a string"),
        (lambda d: d.__setitem__("changed_files_covered", 3), "a count instead of a list"),
        (lambda d: d.__setitem__("baseline_report", ""), "an empty baseline"),
    ],
)
def test_a_malformed_diff_stamp_fails(mutate, why):
    stamp = dict(COVERAGE_DIFF)
    mutate(stamp)
    assert _errors("vuln-findings", COVERAGE_DIFF_POINTER, stamp), why


def test_a_full_scan_omits_the_stamp():
    meta_pointer = "/$defs/metadata/properties/additional"
    assert (
        _errors("vuln-findings", meta_pointer, {"deterministic_steps": {"opengrep": "ran"}}) == []
    )


def _vuln_findings(record: dict | None, stamp: dict | None = None) -> dict:
    document = json.loads(sample("vuln-findings")[0])
    if record is not None:
        document["review_surface_coverage"] = record
    if stamp is not None:
        document["metadata"]["additional"] = {"coverage_diff": stamp}
    return document


def _report_errors(document: dict) -> list[str]:
    return _errors("vuln-findings", "", document)


def test_a_diff_scan_may_answer_out_of_scope():
    record = _scan_record()
    record["credential-acceptance"]["finding_ids"] = ["REPO-abcdef0-001"]
    assert _report_errors(_vuln_findings(record, COVERAGE_DIFF)) == []


def test_a_full_scan_may_not_answer_out_of_scope():
    record = _scan_record()
    assert _report_errors(_vuln_findings(record))
    with_other_additional = _vuln_findings(record)
    with_other_additional["metadata"]["additional"] = {"deterministic_steps": {"opengrep": "ran"}}
    assert _report_errors(with_other_additional)


def test_a_full_scan_without_out_of_scope_needs_no_stamp():
    record = {s: {"status": "negative", "note": "examined, clean"} for s in SURFACES}
    assert _report_errors(_vuln_findings(record)) == []
    assert _report_errors(_vuln_findings(None)) == []
