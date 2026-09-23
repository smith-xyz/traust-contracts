"""Review submission provenance is optional, typed, and retained without defaults."""

from __future__ import annotations

import json
import sqlite3
from contextlib import closing
from typing import Any

import pytest
from jsonschema import ValidationError

from traust_contracts.v1.storage import Binding, Store
from traust_contracts.v1.storage.store import validators

ACTOR = {
    "kind": "machine",
    "identity": "fixture-submitter",
    "identity_verified": True,
    "identity_provider": "oidc",
    "identity_issuer": "https://identity.example.test",
    "identity_subject": "fixture-subject",
}


def document() -> dict[str, Any]:
    return {
        "metadata": {
            "audit_report": "report.json",
            "repository": "https://example.test/repository",
            "created": "2026-01-01T00:00:00Z",
            "harness_version": "0.1.0",
        },
        "events": [],
        "needs_review": [
            {
                "queued_at": "2026-01-01T00:00:00Z",
                "source_ref": "https://example.test/review/1",
                "quote": "This requires review.",
                "author": "original-author",
                "status": "pending",
            }
        ],
    }


@pytest.mark.parametrize("include_actor", [False, True])
def test_optional_actor_survives_storage_unchanged(include_actor: bool) -> None:
    data = document()
    if include_actor:
        data["needs_review"][0]["submitted_by"] = ACTOR
    payload = json.dumps(data, indent=2).encode() + b"\n"
    with closing(sqlite3.connect(":memory:")) as conn:
        store = Store(conn)
        store.init()
        saved = store.ingest("layer", payload, Binding(layer_id="fixture-layer"))
        assert store.get_evidence(saved.digest) == payload
    assert "submitted_by" not in validators()["layer"].schema["$defs"]["review_item"]["required"]


@pytest.mark.parametrize(
    "actor",
    [
        None,
        {},
        {"kind": "unknown"},
        {"kind": "machine", "identity_verified": "true"},
        {"kind": "machine", "unexpected": "field"},
    ],
)
def test_present_actor_must_match_the_existing_actor_contract(actor: object) -> None:
    data = document()
    data["needs_review"][0]["submitted_by"] = actor
    with pytest.raises(ValidationError):
        validators()["layer"].validate(data)
