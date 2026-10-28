"""Tier 2 settings kinds and the Tier 1 traust.yaml schema."""

from __future__ import annotations

import json
from pathlib import Path

import pytest
from jsonschema import FormatChecker
from jsonschema.validators import validator_for

REPO_ROOT = Path(__file__).parent.parent
SCHEMA_DIR = REPO_ROOT / "artifacts_schema" / "v1"
KINDS = json.loads((REPO_ROOT / "enums/v1/settings-kind.json").read_text(encoding="utf-8"))
REVISION = {
    "set_by": "human:alice@example.com",
    "reason": "tighten",
    "set_at": "2026-11-02T10:00:00Z",
}


def _schema(name: str) -> dict:
    return json.loads((SCHEMA_DIR / f"{name}.schema.json").read_text(encoding="utf-8"))


def _errors(schema: dict, document: object) -> list[str]:
    validator = validator_for(schema)(schema, format_checker=FormatChecker())
    return [e.message for e in validator.iter_errors(document)]


def test_every_settings_kind_is_an_artifact_schema_of_the_same_name():
    assert sorted(KINDS["values"]) == sorted(
        k for k in KINDS["values"] if (SCHEMA_DIR / f"{k}.schema.json").is_file()
    )
    assert "compliance-scope" not in KINDS["values"]


def test_every_settings_kind_carries_the_same_optional_revision_block():
    revisions = {k: _schema(k)["properties"].get("revision") for k in KINDS["values"]}
    assert all(revisions.values()), [k for k, r in revisions.items() if r is None]
    assert len({json.dumps(r, sort_keys=True) for r in revisions.values()}) == 1
    assert not any("revision" in _schema(k).get("required", []) for k in KINDS["values"])


@pytest.mark.parametrize(
    "revision",
    [
        {k: v for k, v in REVISION.items() if k != "reason"},
        {**REVISION, "reason": ""},
        {**REVISION, "set_at": "yesterday"},
        {**REVISION, "approved_by": "bob"},
    ],
)
def test_revision_needs_who_why_and_when_and_nothing_else(revision):
    schema = _schema("execution-boundaries")
    assert _errors(schema, {"version": 1, "sandbox": "none", "revision": REVISION}) == []
    assert _errors(schema, {"version": 1, "sandbox": "none", "revision": revision})


VALID = {
    "budget": [
        {"lanes": []},
        {
            "lanes": [
                {"lane": "full-audit+validate", "monthly_usd": 1200.5, "enforcement": "advisory"}
            ],
            "policy": {
                "version": 1,
                "enforcement": "observe",
                "monthly_budget": {"usd_central": 23000, "note": "a band"},
                "bands": [{"at": 1.5, "action": "warn"}],
            },
        },
    ],
    "rule-pack-allowlist": [
        {"packs": {}},
        {
            "packs": {
                "some-rules": {
                    "enabled": True,
                    "source": "https://example.com/r@abc",
                    "rules": ["a"],
                }
            }
        },
    ],
    "feed-access": [
        {"sources": {}},
        {"sources": {"osv": {"access": "air-gapped"}, "deps_dev": {"access": "disabled"}}},
    ],
    "execution-boundaries": [
        {"version": 1, "sandbox": "none"},
        {"version": 1, "sandbox": "podman"},
    ],
    "remediation-target": [
        {"fork_org": "example-mirrors"},
        {
            "fork_org": "example-mirrors",
            "naming_prefix": "traust",
            "fix_branch_prefix": "fix",
            "private_forge_hosts": ["gitlab.example.internal"],
        },
    ],
    "product-definitions-map": [
        {"mappings": {}},
        {
            "mappings": {
                "packages": {"pkg-findings": "product"},
                "repos": {"https://example.com/r": "p"},
            }
        },
    ],
}
INVALID = {
    "budget": [
        {},
        {"lanes": [{"lane": "full-audit", "monthly_usd": -1, "enforcement": "advisory"}]},
        {"lanes": [{"lane": "full-audit", "monthly_usd": 1, "enforcement": "strict"}]},
        {"lanes": [], "policy": {"monthly_budget": {"usd_central": 1}}},
        {"lanes": [], "budget_policy": {"enforcement": "observe"}},
    ],
    "rule-pack-allowlist": [{}, {"packs": {"Bad Name": {}}}, {"packs": {"p": {"enabled": "yes"}}}],
    "feed-access": [{}, {"sources": {"osv": {"access": "offline"}}}, {"sources": {"osv": {}}}],
    "execution-boundaries": [{"sandbox": "none"}, {"version": 1, "sandbox": "docker"}],
    "remediation-target": [
        {},
        {"fork_org": "has space"},
        {"fork_org": "o", "fix_branch_prefix": "a/b"},
        {"fork_org": "o", "private_forge_hosts": ["h", "h"]},
    ],
    "product-definitions-map": [
        {},
        {"mappings": {"packages": {"pkg": 3}}},
        {"mappings": {"teams": {}}},
    ],
}


@pytest.mark.parametrize(("kind", "document"), [(k, d) for k, ds in VALID.items() for d in ds])
def test_new_settings_kinds_accept_their_documents(kind, document):
    assert _errors(_schema(kind), document) == []
    assert _errors(_schema(kind), {**document, "revision": REVISION}) == []


@pytest.mark.parametrize(("kind", "document"), [(k, d) for k, ds in INVALID.items() for d in ds])
def test_new_settings_kinds_reject_malformed_documents(kind, document):
    assert _errors(_schema(kind), document)


TRAUST = json.loads((REPO_ROOT / "config/v1/traust.schema.json").read_text(encoding="utf-8"))
FULL = {
    "home": "~/.traust",
    "database": {
        "url": "postgresql+psycopg://traust@db.example/traust",
        "password_env": "TRAUST_DB_PASSWORD",
    },
    "artifacts": {"path": "artifacts"},
    "process": {"allowed_binaries": ["git"], "keep_env": ["PATH"], "timeout_seconds": 60},
    "http": {
        "max_attempts": 4,
        "timeout_seconds": 120,
        "backoff_base_seconds": 1,
        "max_wait_seconds": 60,
        "jitter_seconds": 0.5,
    },
    "logging": {
        "level": "INFO",
        "levels": {"traust_core.rest.access": "WARNING"},
        "format": "text",
        "file": "logs/t.log",
        "max_bytes": 2048,
        "backups": 2,
    },
    "review": {"valve_salt_env": "TRAUST_VALVE_SALT"},
    "ledger": {
        "key_path": "/run/secrets/cosign.key",
        "public_key_path": "/etc/traust/cosign.pub",
        "required": True,
    },
    "identity": {
        "issuers": [
            {
                "issuer": "https://sso.example",
                "jwks_url": "https://sso.example/keys",
                "audience": "traust",
            }
        ],
        "trust_local": False,
        "admins": ["alice@example.com"],
        "login": {"issuer": "https://sso.example", "client_id": "traust-cli"},
    },
    "recording": {"triage": ["triage"]},
    "allowed_repo_hosts": ["github.com"],
    "forge_hosts": {"github.com": "github", "gitlab.example": "gitlab"},
    "locations": {
        "workspace": "../..",
        "analysis_results": "file:///data/results",
        "inputs": "../inputs",
    },
}


def test_traust_yaml_empty_is_a_laptop_install_and_the_full_shape_validates():
    assert _errors(TRAUST, {}) == []
    assert _errors(TRAUST, FULL) == []


@pytest.mark.parametrize(
    "document",
    [
        {"budgets": []},
        {"remediation": {"fork_org": "o"}},
        {"rating": {"sla": {}}},
        {"storage": {"dsn": "sqlite:///x"}},
        {"database": {"password": "hunter2"}},
        {"database": {"password_env": "not-an-env-name"}},
        {"identity": {"issuers": [{"issuer": "https://i", "jwks_url": "http://insecure"}]}},
        {"locations": {"workspace": "/w", "unknown": "/u"}},
        {"logging": {"levels": {"other.logger": "INFO"}}},
        {"forge_hosts": {"git.example": "bitbucket"}},
    ],
)
def test_traust_yaml_rejects_tier_2_settings_secrets_and_typos(document):
    assert _errors(TRAUST, document)
