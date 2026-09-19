"""Reference storage/v1 protocol: sqlite3 complete; optional psycopg>=3 for PostgreSQL."""

from __future__ import annotations

import hashlib
import json
import re
import sqlite3
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from datetime import UTC, datetime
from functools import cache
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker, ValidationError
from referencing import Registry, Resource

from traust_contracts.paths import schema_dir, storage_dir
from traust_contracts.v1.storage.sql import (
    CONTRACT_VERSION,
    REVISION,
    Dialect,
    bootstrap_files,
    bootstrap_statements,
    query,
)

SQLValue = str | int | float | bytes | None
DIGEST_PATTERN = re.compile(r"^[0-9a-f]{64}$")
BINDING_DOMAIN = b"traust-binding-v1\x00"


ONE_ROW_PROJECTIONS: dict[str, tuple[str, tuple[tuple[str, str], ...]]] = {
    "adapter-result": (
        "adapter_result",
        (
            ("target", "scalar"),
            ("scanned_at", "scalar"),
            ("metadata", "json"),
            ("findings", "json"),
            ("summary", "json"),
            ("focus_areas", "json"),
        ),
    ),
    "adr-registry": (
        "adr_registry",
        (("version", "integer"), ("note", "scalar"), ("registers", "json")),
    ),
    "attack-mapping": (
        "attack_mapping",
        (
            ("mapping_version", "scalar"),
            ("attack_version", "scalar"),
            ("source", "scalar"),
            ("documentation", "scalar"),
            ("schema", "scalar"),
            ("attribution", "scalar"),
            ("capability_map", "json"),
            ("category_map", "json"),
        ),
    ),
    "benchmark-target": (
        "benchmark_target",
        (("version", "integer"), ("updated", "scalar"), ("targets", "json")),
    ),
    "cloud-config-audit": (
        "cloud_config_audit",
        (
            ("title", "scalar"),
            ("metadata", "json"),
            ("summary", "json"),
            ("findings", "json"),
            ("gaps", "json"),
        ),
    ),
    "cloud-config-findings-current": (
        "cloud_config_findings_current",
        (
            ("title", "scalar"),
            ("metadata", "json"),
            ("summary", "json"),
            ("findings", "json"),
            ("gaps", "json"),
            ("disposition_summary", "json"),
        ),
    ),
    "compliance-assessment": (
        "compliance_assessment",
        (("metadata", "json"), ("coverage", "json"), ("results", "json")),
    ),
    "compliance-mapping": (
        "compliance_mapping",
        (("version", "integer"), ("note", "scalar"), ("controls", "json"), ("checks", "json")),
    ),
    "compliance-scope": (
        "compliance_scope",
        (("version", "integer"), ("updated", "scalar"), ("boundaries", "json")),
    ),
    "doc-variance": ("doc_variance", (("metadata", "json"), ("records", "json"))),
    "fleet-fix": (
        "fleet_fix",
        (
            ("id", "scalar"),
            ("pattern_ref", "scalar"),
            ("description", "scalar"),
            ("matcher", "json"),
            ("resolver", "json"),
            ("rewrite", "json"),
            ("guards", "json"),
            ("tests", "json"),
        ),
    ),
    "impact-analysis": (
        "impact_analysis",
        (("metadata", "json"), ("summary", "json"), ("repos", "json")),
    ),
    "isolation-review": (
        "isolation_review",
        (
            ("title", "scalar"),
            ("metadata", "json"),
            ("interfaces", "json"),
            ("gaps", "json"),
            ("posture", "json"),
            ("notes", "scalar"),
        ),
    ),
    "org-parameters": (
        "org_parameters",
        (
            ("version", "integer"),
            ("declared_by", "scalar"),
            ("declared_on", "scalar"),
            ("note", "scalar"),
            ("parameters", "json"),
        ),
    ),
    "pqc-blockers": (
        "pqc_blockers",
        (
            ("artifact", "scalar"),
            ("title", "scalar"),
            ("metadata", "json"),
            ("executive_summary", "json"),
            ("severity_criteria", "json"),
            ("findings", "json"),
            ("findings_summary", "json"),
            ("remediation_roadmap", "json"),
        ),
    ),
    "pqc-decision-tree": (
        "pqc_decision_tree",
        (
            ("tree_version", "scalar"),
            ("plan", "scalar"),
            ("schema", "scalar"),
            ("provenance_tree", "json"),
            ("remediation_effort", "json"),
            ("readiness_buckets", "json"),
            ("tls_control_crosswalk", "json"),
            ("fips_interaction", "json"),
            ("pqc_classification_map", "json"),
            ("server_side_caveat", "json"),
        ),
    ),
    "pqc-facts": (
        "pqc_facts",
        (
            ("artifact", "scalar"),
            ("repository", "scalar"),
            ("stamps", "json"),
            ("coverage", "json"),
            ("summary", "json"),
            ("facts", "json"),
        ),
    ),
    "pqc-readiness": (
        "pqc_readiness",
        (
            ("title", "scalar"),
            ("metadata", "json"),
            ("scores", "json"),
            ("flags", "json"),
            ("provenance_summary", "json"),
            ("clock_items", "json"),
            ("readiness_bucket", "scalar"),
            ("fips_interaction", "json"),
            ("runtime_evidence", "json"),
            ("server_side_caveats", "json"),
            ("notes", "scalar"),
            ("remediations", "json"),
        ),
    ),
    "remediation": (
        "remediation",
        (
            ("title", "scalar"),
            ("metadata", "json"),
            ("source_findings", "json"),
            ("fork", "json"),
            ("patch", "json"),
            ("checks", "json"),
            ("evidence", "json"),
            ("revalidation", "json"),
            ("pull_request", "json"),
            ("summary", "json"),
            ("notes", "scalar"),
            ("footer", "scalar"),
        ),
    ),
    "report": (
        "report",
        (
            ("title", "scalar"),
            ("metadata", "json"),
            ("executive_summary", "json"),
            ("severity_criteria", "json"),
            ("findings", "json"),
            ("findings_summary", "json"),
            ("remediation_roadmap", "json"),
            ("dependency_audit", "json"),
            ("negative_results", "json"),
            ("asvs_coverage", "json"),
            ("scanner_correlation", "json"),
            ("peach_isolation_review", "json"),
            ("disposition_summary", "json"),
            ("footer", "scalar"),
        ),
    ),
    "risk-rating-methodology": (
        "risk_rating_methodology",
        (
            ("methodology", "scalar"),
            ("methodology_version", "scalar"),
            ("source", "scalar"),
            ("documentation", "scalar"),
            ("schema", "scalar"),
            ("bands", "json"),
            ("bucket_thresholds", "json"),
            ("likelihood_factors", "json"),
            ("impact_factors", "json"),
            ("matrix", "json"),
            ("fallback", "json"),
            ("threat_intel_factor", "json"),
        ),
    ),
    "sla-policy": (
        "sla_policy",
        (
            ("policy_name", "scalar"),
            ("source", "json"),
            ("severity_mapping", "json"),
            ("clock_start", "scalar"),
            ("profiles", "json"),
        ),
    ),
    "validation": (
        "validation",
        (
            ("title", "scalar"),
            ("metadata", "json"),
            ("source_reports", "json"),
            ("summary", "json"),
            ("validated_findings", "json"),
            ("attack_chains", "json"),
            ("novel_findings", "json"),
            ("negative_results", "json"),
            ("execution_log_ref", "scalar"),
            ("execution_log_sha256", "scalar"),
            ("footer", "scalar"),
        ),
    ),
    "verification": (
        "verification",
        (
            ("title", "scalar"),
            ("metadata", "json"),
            ("summary", "json"),
            ("verified_findings", "json"),
            ("regressions", "json"),
            ("commit_timeline", "json"),
            ("evidence", "json"),
            ("recommendations", "json"),
            ("notes", "scalar"),
            ("footer", "scalar"),
        ),
    ),
}


@dataclass(frozen=True)
class Binding:
    scope_id: str = "local"
    subject_id: str | None = None
    run_id: str | None = None
    layer_id: str | None = None
    supersedes_binding_id: str | None = None


@dataclass(frozen=True)
class BindingRecord:
    binding_id: str
    artifact_digest: str
    artifact_name: str
    binding: Binding
    bound_at: str


@dataclass(frozen=True)
class IngestResult:
    digest: str
    binding_id: str
    already_bound: bool = False


class IngestError(ValueError):
    """Log-safe failure; original bytes require explicit access through payload."""

    def __init__(self, message: str, *, artifact: str = "", payload: bytes = b"") -> None:
        super().__init__(message)
        self.artifact = artifact
        self.payload = payload


def _error_detail(error: Exception) -> str:
    """Driver/validator messages and chained tracebacks can contain artifact contents."""
    if isinstance(error, IngestError):
        return str(error)
    if isinstance(error, ValidationError):
        path = "/".join(str(token) for token in error.absolute_schema_path)
        return f"schema rule {error.validator} at /{path}"
    if isinstance(error, json.JSONDecodeError):
        return f"invalid JSON at line {error.lineno}, column {error.colno}"
    code = getattr(error, "sqlite_errorname", None) or getattr(error, "sqlstate", None)
    return type(error).__name__ + (f" [{code}]" if code else "")


@cache
def validators() -> dict[str, Draft202012Validator]:
    schemas = {
        path.name.removesuffix(".schema.json"): json.loads(path.read_text(encoding="utf-8"))
        for path in sorted(schema_dir().glob("*.schema.json"))
    }
    registry = Registry().with_resources(
        (schema["$id"], Resource.from_contents(schema)) for schema in schemas.values()
    )
    return {
        name: Draft202012Validator(schema, registry=registry, format_checker=FormatChecker())
        for name, schema in schemas.items()
    }


@cache
def storage_profiles() -> dict[str, dict[str, Any]]:
    document = json.loads((storage_dir() / "profiles.json").read_text(encoding="utf-8"))
    profiles = document["artifacts"]
    if set(profiles) != set(validators()):
        raise ValueError("storage profiles must cover every artifact schema exactly")
    tables = {
        **{name: table for name, (table, _) in ONE_ROW_PROJECTIONS.items()},
        # Families that fan out to a differently-named table rather than
        # taking the one-row default.
        "layer": "layer_metadata",
        "triage": "triage_verdict",
        "vuln-findings": "finding",
        "corpus-registry": "subject_ownership",
        "threat-register": "threat",
        "operator-priv-profile": "priv_profile",
    }
    for name, profile in profiles.items():
        if profile.get("projection") != tables[name]:
            raise ValueError(f"storage profile {name} has the wrong projection table")
    return profiles


def _reject_constant(value: str) -> Any:
    raise ValueError(f"non-JSON numeric constant: {value}")


def _integer(value: int | float | None) -> int | None:
    """JSON Schema accepts integral floats; drivers need actual integers."""
    if value is None:
        return None
    if type(value) is int or (type(value) is float and value.is_integer()):
        return int(value)
    raise ValueError(f"expected int, got {type(value).__name__}")


def _boolean(value: bool | None) -> int | None:
    """Store a flag as 0/1 in an INTEGER column on BOTH dialects.

    storage/v1 has no BOOLEAN anywhere -- even traust_storage_meta uses
    INTEGER on PostgreSQL -- and the Go generator refuses a table whose
    column types differ between dialects, which is how the first attempt
    at this was caught.

    Absent stays absent: a disposition flag that was never set is NULL, not
    False. "Nobody overrode this false positive" and "we have no record
    either way" are different claims, and the two-person rule depends on the
    difference.
    """
    if value is None:
        return None
    if type(value) is not bool:
        raise ValueError(f"expected bool, got {type(value).__name__}")
    return int(value)


def _json_or_none(value: Any) -> str | None:
    """Encode a nested block for a JSON column, canonically. None stays None."""
    if value is None:
        return None
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"), allow_nan=False)


def _identifier_bytes(field: str, value: str) -> bytes:
    if not isinstance(value, str):
        raise IngestError(f"{field}: expected string")
    if "\x00" in value:
        raise IngestError(f"{field}: NUL is not allowed")
    try:
        return value.encode("utf-8")
    except UnicodeEncodeError:
        raise IngestError(f"{field}: invalid Unicode") from None


def binding_id(artifact_digest: str, artifact_name: str, binding: Binding) -> str:
    """Return the storage/v1 binding identity over the specified byte tuple."""
    required = (artifact_digest, artifact_name, binding.scope_id)
    encoded = bytearray(BINDING_DOMAIN)
    for field, value in zip(
        ("artifact_digest", "artifact_name", "scope_id"), required, strict=True
    ):
        encoded.extend(_identifier_bytes(field, value))
        encoded.append(0)
    for field, value in (
        ("subject_id", binding.subject_id),
        ("run_id", binding.run_id),
        ("layer_id", binding.layer_id),
    ):
        if value is None:
            encoded.append(0)
        else:
            encoded.append(1)
            encoded.extend(_identifier_bytes(field, value))
            encoded.append(0)
    return hashlib.sha256(encoded).hexdigest()


class Store:
    """Caller-owned idle connection, tuple rows; never closes it or owns caller work."""

    def __init__(self, conn: Any) -> None:
        self.conn = conn
        self.dialect: Dialect
        if isinstance(conn, sqlite3.Connection):
            self.dialect = "sqlite"
            conn.execute("PRAGMA foreign_keys = ON")
        else:
            try:
                import psycopg
            except ImportError as error:
                raise ValueError(
                    "expected sqlite3.Connection or install traust-contracts[postgres]"
                ) from error
            if not isinstance(conn, psycopg.Connection):
                raise ValueError("expected sqlite3.Connection or psycopg.Connection")
            if conn.info.server_version < 140000:
                raise ValueError("storage requires PostgreSQL >=14")
            self.dialect = "postgres"

    def _active(self) -> bool:
        return (
            self.conn.in_transaction
            if self.dialect == "sqlite"
            else self.conn.info.transaction_status != 0
        )

    def _rollback(self) -> str:
        try:
            if self._active():
                self.conn.execute("ROLLBACK")
        except Exception as error:
            return f"; rollback failed: {_error_detail(error)}"
        return ""

    def _idle(self, artifact: str = "", payload: bytes = b"") -> None:
        if self._active():
            raise IngestError(
                "storage requires an idle connection; caller transaction is untouched",
                artifact=artifact,
                payload=payload,
            )

    def _execute(self, sql: str, values: Mapping[str, SQLValue] | None = None) -> Any:
        return self.conn.execute(sql, values) if values is not None else self.conn.execute(sql)

    def _begin(self, artifact: str = "", payload: bytes = b"") -> None:
        try:
            self.conn.execute(
                "BEGIN IMMEDIATE"
                if self.dialect == "sqlite"
                else "BEGIN ISOLATION LEVEL READ COMMITTED"
            )
        except Exception as error:
            raise IngestError(
                f"artifact {artifact}: begin transaction: {_error_detail(error)}",
                artifact=artifact,
                payload=payload,
            ) from None

    def init(self) -> None:
        """Initialize a fresh database or verify its exact version; never imply a migration."""
        self._idle()
        self._begin()
        try:
            if self.dialect == "postgres":
                self._execute(query(self.dialect, "traust_storage_meta.lock.sql"))
            exists = self._execute(query(self.dialect, "traust_storage_meta.exists.sql")).fetchone()
            row = (
                self._execute(query(self.dialect, "traust_storage_meta.get.sql")).fetchone()
                if exists and exists[0]
                else None
            )
            if row and (row[0] != CONTRACT_VERSION or row[1] != REVISION):
                raise IngestError(
                    f"database storage {row[0]} revision {row[1]}; "
                    f"package {CONTRACT_VERSION} revision {REVISION}: "
                    "explicit migration required; automatic upgrades/downgrades are not supported"
                )
            if not row:
                for path in bootstrap_files(self.dialect):
                    for statement in bootstrap_statements(self.dialect, path):
                        self._execute(statement)
                self._execute(
                    query(self.dialect, "traust_storage_meta.upsert.sql"),
                    {
                        "contract_version": CONTRACT_VERSION,
                        "revision": REVISION,
                        "applied_at": datetime.now(UTC).isoformat(),
                    },
                )
            self.conn.execute("COMMIT")
        except Exception as error:
            rollback_error = self._rollback()
            raise IngestError(f"storage init: {_error_detail(error)}{rollback_error}") from None

    def get_evidence(self, digest: str) -> bytes:
        """Return exact evidence bytes without making a schema claim."""
        self._idle()
        if not isinstance(digest, str) or not DIGEST_PATTERN.fullmatch(digest):
            raise IngestError("artifact not found")
        self._begin()
        try:
            payload = self._evidence(digest)
            self.conn.execute("COMMIT")
            return payload
        except Exception as error:
            rollback_error = self._rollback()
            raise IngestError(
                f"storage evidence read: {_error_detail(error)}{rollback_error}"
            ) from None

    def get_binding(self, binding_id_value: str) -> BindingRecord:
        """Return one binding without interpreting its evidence."""
        self._idle()
        if not isinstance(binding_id_value, str) or not DIGEST_PATTERN.fullmatch(binding_id_value):
            raise IngestError("artifact binding not found")
        self._begin()
        try:
            row = self._binding_row(binding_id_value)
            if row is None:
                raise IngestError("artifact binding not found")
            record = self._binding_record(binding_id_value, row)
            self.conn.execute("COMMIT")
            return record
        except Exception as error:
            rollback_error = self._rollback()
            raise IngestError(
                f"storage binding read: {_error_detail(error)}{rollback_error}"
            ) from None

    def get(self, artifact: str, binding_id_value: str) -> bytes:
        """Return exact validated evidence through a type-checked binding."""
        self._idle(artifact)
        validator = validators().get(artifact) if isinstance(artifact, str) else None
        if validator is None:
            raise IngestError("unknown artifact schema", artifact=artifact)
        if not isinstance(binding_id_value, str) or not DIGEST_PATTERN.fullmatch(binding_id_value):
            raise IngestError("artifact binding not found", artifact=artifact)
        self._begin(artifact)
        try:
            row = self._binding_row(binding_id_value)
            if row is None:
                raise IngestError("artifact binding not found")
            record = self._binding_record(binding_id_value, row)
            if record.artifact_name != artifact:
                raise IngestError("artifact type mismatch")
            payload = self._evidence(record.artifact_digest)
            document = json.loads(payload, parse_constant=_reject_constant)
            validator.validate(document)
            self.conn.execute("COMMIT")
            return payload
        except Exception as error:
            rollback_error = self._rollback()
            raise IngestError(
                f"storage read {artifact}: {_error_detail(error)}{rollback_error}",
                artifact=artifact,
            ) from None

    def ingest(
        self,
        artifact: str,
        payload: bytes,
        binding: Binding | None = None,
    ) -> IngestResult:
        """Validate exact bytes, bind context, and project atomically, or write nothing."""
        self._idle(artifact, payload)
        binding = binding or Binding()
        validator = None
        try:
            validator = validators().get(artifact) if isinstance(artifact, str) else None
            if validator is None:
                raise IngestError("unknown artifact schema")
            if not isinstance(payload, bytes):
                raise IngestError("payload must be bytes")
            document = json.loads(payload, parse_constant=_reject_constant)
            validator.validate(document)
            self._validate_binding(artifact, binding)
        except Exception as error:
            label = artifact if validator is not None else "<unknown>"
            raise IngestError(
                f"artifact {label}: validation: {_error_detail(error)}",
                artifact=artifact,
                payload=payload,
            ) from None

        digest = hashlib.sha256(payload).hexdigest()
        binding_id_value = binding_id(digest, artifact, binding)
        self._begin(artifact, payload)
        context = f"artifact {artifact}"
        try:
            if self.dialect == "postgres":
                self._execute(
                    query(self.dialect, "artifact.lock.sql"),
                    {"lock_key": int.from_bytes(bytes.fromhex(digest)[:8], signed=True)},
                )
            existing = self._binding_row(binding_id_value)
            if existing is not None:
                self._require_same_binding(binding_id_value, artifact, digest, binding, existing)
                self.conn.execute("COMMIT")
                return IngestResult(digest, binding_id_value, already_bound=True)
            if binding.supersedes_binding_id is not None:
                self._require_predecessor(artifact, binding_id_value, binding)

            context = f"artifact {artifact}, table artifact_evidence"
            self._execute(
                query(self.dialect, "artifact_evidence.upsert.sql"),
                {
                    "digest": digest,
                    "payload": payload,
                    "first_ingested_at": datetime.now(UTC).isoformat(),
                },
            )
            if self._evidence(digest) != payload:
                raise IngestError("artifact evidence digest collision")
            context = f"artifact {artifact}, table artifact_binding"
            self._execute(
                query(self.dialect, "artifact_binding.upsert.sql"),
                {
                    "binding_id": binding_id_value,
                    "artifact_digest": digest,
                    "artifact_name": artifact,
                    "scope_id": binding.scope_id,
                    "subject_id": binding.subject_id,
                    "run_id": binding.run_id,
                    "layer_id": binding.layer_id,
                    "supersedes_binding_id": binding.supersedes_binding_id,
                    "bound_at": datetime.now(UTC).isoformat(),
                },
            )
            projection = storage_profiles()[artifact].get("projection")
            if projection is not None:
                context = f"artifact {artifact}, table {projection}"
            self._project(artifact, document, digest, binding_id_value)
            self.conn.execute("COMMIT")
            return IngestResult(digest, binding_id_value)
        except Exception as error:
            rollback_error = self._rollback()
            raise IngestError(
                f"{context}: {_error_detail(error)}{rollback_error}",
                artifact=artifact,
                payload=payload,
            ) from None

    def query_findings_summary(self, scope_ids: Sequence[str]) -> list[tuple[Any, ...]]:
        """Return findings summary rows visible to the explicit scope list."""
        self._idle()
        if not scope_ids:
            raise IngestError("storage scope is required")
        for scope_id in scope_ids:
            _identifier_bytes("scope_id", scope_id)
        encoded = json.dumps(list(scope_ids), ensure_ascii=False, separators=(",", ":"))
        self._begin()
        try:
            if self.dialect == "postgres":
                self._execute(query(self.dialect, "scope.set.sql"), {"scope_ids": encoded})
            rows = self._execute(
                query(self.dialect, "findings_summary.list.sql"), {"scope_ids": encoded}
            ).fetchall()
            self.conn.execute("COMMIT")
            return rows
        except Exception as error:
            rollback_error = self._rollback()
            raise IngestError(
                f"storage findings summary read: {_error_detail(error)}{rollback_error}"
            ) from None

    def _query_view(self, view: str, scope_ids: Sequence[str]) -> list[tuple[Any, ...]]:
        """Read a scope-gated dashboard view. One implementation, not four.

        Every dashboard read goes through here so the scope contract is
        stated once: PostgreSQL fails CLOSED, returning zero rows rather
        than erroring when no scope is set, which reads as "no findings"
        when it means "misconfigured". An empty list is refused for the
        same reason.
        """
        self._idle()
        if not scope_ids:
            raise IngestError("storage scope is required")
        for scope_id in scope_ids:
            _identifier_bytes("scope_id", scope_id)
        encoded = json.dumps(list(scope_ids), ensure_ascii=False, separators=(",", ":"))
        self._begin()
        try:
            if self.dialect == "postgres":
                self._execute(query(self.dialect, "scope.set.sql"), {"scope_ids": encoded})
            rows = self._execute(
                query(self.dialect, f"{view}.list.sql"), {"scope_ids": encoded}
            ).fetchall()
            self.conn.execute("COMMIT")
            return rows
        except Exception as error:
            rollback_error = self._rollback()
            raise IngestError(
                f"storage {view} read: {_error_detail(error)}{rollback_error}"
            ) from None

    def query_open_findings(self, scope_ids: Sequence[str]) -> list[tuple[Any, ...]]:
        """Open exposure: not affirmatively closed, not FP, not hardening."""
        return self._query_view("open_findings", scope_ids)

    def query_hardening_findings(self, scope_ids: Sequence[str]) -> list[tuple[Any, ...]]:
        """Posture debt, kept out of open exposure so the two never blend."""
        return self._query_view("hardening_findings", scope_ids)

    def query_distinct_exposure(self, scope_ids: Sequence[str]) -> list[tuple[Any, ...]]:
        """Lens 2: distinct problems over owned HEAD audits, not row counts."""
        return self._query_view("distinct_exposure", scope_ids)

    def query_census_population(self, scope_ids: Sequence[str]) -> list[tuple[Any, ...]]:
        """The denominator, per tree -- counted from ownership, not findings.

        `with_report` is the coverage numerator. A subject with no finding
        is still coverage; a denominator built from findings silently drops
        it and overstates every percentage computed against it.
        """
        return self._query_view("census_population", scope_ids)

    def query_threat_current(self, scope_ids: Sequence[str]) -> list[tuple[Any, ...]]:
        """Modelled threats from the current register, with their owner."""
        return self._query_view("threat_current", scope_ids)

    def query_threat_exposure(self, scope_ids: Sequence[str]) -> list[tuple[Any, ...]]:
        """Threats aggregated by impact/likelihood/status, and whether evidenced.

        status stays UNCOLLAPSED: partially_mitigated is the largest bucket
        in practice, so folding it into mitigated overstates threat coverage
        more than any other choice available here.
        """
        return self._query_view("threat_exposure", scope_ids)

    def query_operator_privilege(self, scope_ids: Sequence[str]) -> list[tuple[Any, ...]]:
        """Privilege each operator ASKS FOR, parsed from shipped manifests.

        Declared state only -- never a live cluster read. Read as a runtime
        grant it is simply wrong.
        """
        return self._query_view("operator_privilege", scope_ids)

    def query_census_exposure(self, scope_ids: Sequence[str]) -> list[tuple[Any, ...]]:
        """Every finding classified once into an exhaustive exposure_class.

        The census asks several questions of one population -- owned,
        upstream, external-bu, cloud-config, branch re-audits -- and each is
        this data filtered differently. Consumers FILTER this; they do not
        restate the disposition policy, which is where the numbers drifted.
        """
        return self._query_view("census_exposure", scope_ids)

    def _validate_binding(self, artifact: str, binding: Binding) -> None:
        if not isinstance(binding, Binding):
            raise IngestError("binding: expected Binding")
        if binding.scope_id == "":
            raise IngestError("scope_id: required value missing")
        _identifier_bytes("scope_id", binding.scope_id)
        for field in ("subject_id", "run_id", "layer_id", "supersedes_binding_id"):
            value = getattr(binding, field)
            if value is not None:
                _identifier_bytes(field, value)
        for field in storage_profiles()[artifact]["required"]:
            if getattr(binding, field) is None:
                raise IngestError(f"{field}: required value missing")

    def _evidence(self, digest: str) -> bytes:
        row = self._execute(
            query(self.dialect, "artifact_evidence.get.sql"), {"digest": digest}
        ).fetchone()
        if row is None:
            raise IngestError("artifact not found")
        payload = row[0]
        if hashlib.sha256(payload).hexdigest() != digest:
            raise IngestError("artifact evidence digest mismatch")
        return payload

    def _binding_row(self, binding_id_value: str) -> tuple[Any, ...] | None:
        return self._execute(
            query(self.dialect, "artifact_binding.get.sql"), {"binding_id": binding_id_value}
        ).fetchone()

    @staticmethod
    def _binding_record(binding_id_value: str, row: tuple[Any, ...]) -> BindingRecord:
        digest, name, scope, subject, run, layer, supersedes, bound_at = row
        return BindingRecord(
            binding_id_value,
            digest,
            name,
            Binding(scope, subject, run, layer, supersedes),
            str(bound_at),
        )

    def _require_same_binding(
        self,
        binding_id_value: str,
        artifact: str,
        digest: str,
        binding: Binding,
        row: tuple[Any, ...],
    ) -> None:
        record = self._binding_record(binding_id_value, row)
        if (
            record.artifact_digest != digest
            or record.artifact_name != artifact
            or record.binding != binding
        ):
            raise IngestError("artifact binding identity collision")

    def _require_predecessor(self, artifact: str, binding_id_value: str, binding: Binding) -> None:
        predecessor_id = binding.supersedes_binding_id
        if predecessor_id == binding_id_value:
            raise IngestError("artifact binding cannot supersede itself")
        row = self._binding_row(predecessor_id or "")
        if row is None:
            raise IngestError("superseded artifact binding not found")
        predecessor = self._binding_record(predecessor_id or "", row)
        expected = (
            artifact,
            binding.scope_id,
            binding.subject_id,
            binding.run_id,
            binding.layer_id,
        )
        actual = (
            predecessor.artifact_name,
            predecessor.binding.scope_id,
            predecessor.binding.subject_id,
            predecessor.binding.run_id,
            predecessor.binding.layer_id,
        )
        if actual != expected:
            raise IngestError("superseded artifact binding context mismatch")

    def _project(
        self, artifact: str, document: dict[str, Any], digest: str, binding_id_value: str
    ) -> None:
        if artifact == "layer":
            metadata = document["metadata"]
            self._execute(
                query(self.dialect, "layer_metadata.upsert.sql"),
                {
                    "binding_id": binding_id_value,
                    "artifact_digest": digest,
                    "repo": metadata.get("repository"),
                    "created_at": metadata.get("created"),
                    "merkle_root": metadata.get("merkle_root"),
                    "merkle_epoch": _integer(metadata.get("merkle_epoch")),
                },
            )
        elif artifact == "vuln-findings":
            for finding in document["findings"]:
                self._execute(
                    query(self.dialect, "finding.upsert.sql"),
                    {
                        "binding_id": binding_id_value,
                        "artifact_digest": digest,
                        "finding_id": finding["id"],
                        "target": document["target"],
                        "scanned_at": document["scanned_at"],
                        "title": finding["title"],
                        "severity": finding["severity"],
                        "description": finding["description"],
                        "category": finding.get("category"),
                        "file": finding["file"],
                        "line": _integer(finding.get("line")),
                        "cwe": finding.get("cwe"),
                        "recommendation": finding["recommendation"],
                        "confidence": finding["confidence"],
                    },
                )
        elif artifact == "triage":
            for finding in document["findings"]:
                votes = finding.get("vote_breakdown")
                self._execute(
                    query(self.dialect, "triage_verdict.upsert.sql"),
                    {
                        "binding_id": binding_id_value,
                        "artifact_digest": digest,
                        "finding_id": finding["id"],
                        "source_finding_id": finding.get("orig_id"),
                        "triage_completed": document["triage_completed"],
                        "verdict": finding["verdict"],
                        "severity": finding.get("severity"),
                        "vote_breakdown": (
                            json.dumps(
                                votes,
                                ensure_ascii=False,
                                separators=(",", ":"),
                                allow_nan=False,
                            )
                            if votes is not None
                            else None
                        ),
                        "rationale": finding.get("rationale"),
                    },
                )
        elif artifact == "cloud-config-findings-current":
            self._project_one_row(artifact, document, digest, binding_id_value)
            self._project_cloud_config_findings(document, digest, binding_id_value)
        elif artifact == "threat-register":
            self._project_threats(document, digest, binding_id_value)
        elif artifact == "operator-priv-profile":
            self._project_priv_profile(document, digest, binding_id_value)
        elif artifact == "corpus-registry":
            for subject in document.get("subjects") or []:
                self._execute(
                    query(self.dialect, "subject_ownership.upsert.sql"),
                    {
                        "binding_id": binding_id_value,
                        "artifact_digest": digest,
                        "subject_id": subject["subject_id"],
                        "tree": subject["tree"],
                        "ownership": subject["ownership"],
                        "business_unit": subject["business_unit"],
                        "label": subject.get("label"),
                        "product": subject.get("product"),
                        "repo_url": subject.get("repo_url"),
                        "ref": subject.get("ref"),
                        "ref_kind": subject.get("ref_kind"),
                        "is_branch_audit": _boolean(subject.get("is_branch_audit")),
                    },
                )
        else:
            self._project_one_row(artifact, document, digest, binding_id_value)
            if artifact == "report":
                self._project_report_findings(document, digest, binding_id_value)

    def _project_one_row(
        self, artifact: str, document: dict[str, Any], digest: str, binding_id_value: str
    ) -> None:
        table, fields = ONE_ROW_PROJECTIONS[artifact]
        values: dict[str, SQLValue] = {
            "binding_id": binding_id_value,
            "artifact_digest": digest,
        }
        for name, kind in fields:
            value = document.get(name)
            if kind == "json" and value is not None:
                value = json.dumps(
                    value,
                    ensure_ascii=False,
                    separators=(",", ":"),
                    allow_nan=False,
                )
            elif kind == "integer":
                value = _integer(value)
            values[name] = value
        self._execute(query(self.dialect, f"{table}.upsert.sql"), values)

    def _project_threats(
        self, document: dict[str, Any], digest: str, binding_id_value: str
    ) -> None:
        """Fan the register's threats out of the JSON blob.

        Keyed on `key`, never `id`: every threat model numbers its threats
        from T1, so `id` collides across the whole model set and an
        id-keyed projection would keep only one threat per number.
        """
        for threat in document.get("threats") or []:
            self._execute(
                query(self.dialect, "threat.upsert.sql"),
                {
                    "binding_id": binding_id_value,
                    "artifact_digest": digest,
                    "threat_key": threat["key"],
                    "threat_id": threat["id"],
                    "model": threat["model"],
                    "subject_id": threat.get("subject_id"),
                    "product": threat.get("product"),
                    "statement": threat.get("threat"),
                    "surface": threat.get("surface"),
                    "asset": threat.get("asset"),
                    "impact": threat.get("impact"),
                    "likelihood": threat.get("likelihood"),
                    "status": threat.get("status"),
                    "controls": threat.get("controls"),
                    "actors": _json_or_none(threat.get("actors")),
                    "evidence": _json_or_none(threat.get("evidence")),
                    "linddun": _boolean(threat.get("linddun")),
                    "score": _integer(threat.get("score")),
                    "isolation_dimensions": _json_or_none(threat.get("isolation_dimensions")),
                    "isolation_boundaries": _json_or_none(threat.get("isolation_boundaries")),
                },
            )

    def _project_priv_profile(
        self, document: dict[str, Any], digest: str, binding_id_value: str
    ) -> None:
        """Lift the summary counts into columns; keep the asks whole.

        Not a plain one-row blob copy: the numbers a least-privilege
        dashboard cuts by live one level down in `summary`, and leaving
        them there means every consumer opens the blob and re-derives them.
        """
        summary = document.get("summary") or {}
        self._execute(
            query(self.dialect, "priv_profile.upsert.sql"),
            {
                "binding_id": binding_id_value,
                "artifact_digest": digest,
                "repo": document["repo"],
                "tier": document.get("tier"),
                "workload_count": _integer(summary.get("workloads")),
                "privileged_or_host_workloads": _integer(
                    summary.get("privileged_or_host_workloads")
                ),
                "rbac_rule_count": _integer(summary.get("rbac_rules")),
                "distinct_rule_triples": _integer(summary.get("distinct_rule_triples")),
                "distinct_cluster_triples": _integer(summary.get("distinct_cluster_triples")),
                "cluster_scoped_rules": _integer(summary.get("cluster_scoped_rules")),
                "wildcard_rules": _integer(summary.get("wildcard_rules")),
                "no_scc_request_recorded": _boolean(summary.get("no_scc_request_recorded")),
                **{
                    field: _json_or_none(document.get(field))
                    for field in (
                        "workloads",
                        "rbac_rules",
                        "rbac_flags",
                        "scc_requests",
                        "sccs_shipped",
                        "namespaces",
                        "install_modes",
                        "operatorgroups",
                        "tier2_required_vs_granted",
                        "example_or_test_manifests_excluded",
                        "summary",
                    )
                },
            },
        )

    def _project_cloud_config_findings(
        self, document: dict[str, Any], digest: str, binding_id_value: str
    ) -> None:
        """Fan a policy report's findings out of the JSON blob.

        Same shape and same reason as _project_report_findings: the blob
        stays authoritative and this is an index over it. Carries the IaC
        columns a policy finding is cut by -- check_id separates two
        findings on one resource, framework and provider slice a compliance
        view.
        """
        for finding in document.get("findings") or []:
            disposition = finding.get("disposition") or {}
            override = disposition.get("severity_override")
            self._execute(
                query(self.dialect, "cloud_config_finding.upsert.sql"),
                {
                    "binding_id": binding_id_value,
                    "artifact_digest": digest,
                    "finding_id": finding["id"],
                    "title": finding.get("title"),
                    "severity": finding.get("severity"),
                    "fingerprint": finding.get("fingerprint"),
                    "validation_status": finding.get("validation_status"),
                    "check_id": finding.get("check_id"),
                    "framework": finding.get("framework"),
                    "provider": finding.get("provider"),
                    "status": finding.get("status"),
                    "scanner_severity": finding.get("scanner_severity"),
                    "validity": disposition.get("validity"),
                    "resolution": disposition.get("resolution"),
                    "assurance": disposition.get("assurance"),
                    "last_updated": disposition.get("last_updated"),
                    "conflict": _boolean(disposition.get("conflict")),
                    "fp_overridden": _boolean(disposition.get("fp_overridden")),
                    "fp_reassertion_blocked": _boolean(disposition.get("fp_reassertion_blocked")),
                    "refuted_awaiting_signoff": _boolean(
                        disposition.get("refuted_awaiting_signoff")
                    ),
                    "severity_override": (
                        json.dumps(
                            override, ensure_ascii=False, separators=(",", ":"), allow_nan=False
                        )
                        if override is not None
                        else None
                    ),
                },
            )

    def _project_report_findings(
        self, document: dict[str, Any], digest: str, binding_id_value: str
    ) -> None:
        """Fan a report's findings out of the JSON blob into queryable rows.

        The blob stays: `report.findings` remains the faithful projection of
        the artifact. This is an index over it, so `validity`/`resolution`
        can be filtered and `fingerprint` grouped without parsing every row.

        Disposition is optional on the artifact -- only cumulative reports
        carry it -- so a finding without one still projects, with its
        identity and NULL disposition.
        """
        for finding in document.get("findings") or []:
            disposition = finding.get("disposition") or {}
            override = disposition.get("severity_override")
            self._execute(
                query(self.dialect, "report_finding.upsert.sql"),
                {
                    "binding_id": binding_id_value,
                    "artifact_digest": digest,
                    "finding_id": finding["id"],
                    "title": finding.get("title"),
                    "severity": finding.get("severity"),
                    "fingerprint": finding.get("fingerprint"),
                    "validation_status": finding.get("validation_status"),
                    "validity": disposition.get("validity"),
                    "resolution": disposition.get("resolution"),
                    "assurance": disposition.get("assurance"),
                    "last_updated": disposition.get("last_updated"),
                    "conflict": _boolean(disposition.get("conflict")),
                    "fp_overridden": _boolean(disposition.get("fp_overridden")),
                    "fp_reassertion_blocked": _boolean(disposition.get("fp_reassertion_blocked")),
                    "refuted_awaiting_signoff": _boolean(
                        disposition.get("refuted_awaiting_signoff")
                    ),
                    "severity_override": (
                        json.dumps(
                            override,
                            ensure_ascii=False,
                            separators=(",", ":"),
                            allow_nan=False,
                        )
                        if override is not None
                        else None
                    ),
                },
            )
