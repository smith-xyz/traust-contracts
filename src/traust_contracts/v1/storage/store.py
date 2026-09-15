"""Reference storage/v1 protocol: sqlite3 complete; optional psycopg>=3 for PostgreSQL."""

from __future__ import annotations

import hashlib
import json
import sqlite3
from collections.abc import Mapping
from dataclasses import dataclass
from datetime import UTC, datetime
from functools import cache
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker, ValidationError
from referencing import Registry, Resource

from traust_contracts.paths import schema_dir
from traust_contracts.v1.storage.sql import (
    CONTRACT_VERSION,
    REVISION,
    Dialect,
    bootstrap_files,
    bootstrap_statements,
    query,
)

SQLValue = str | int | float | bytes | None

# One parent row per layer and schema; nested values remain queryable JSON.
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
            ("recommendations", "json"),
            ("notes", "scalar"),
            ("footer", "scalar"),
        ),
    ),
}


@dataclass(frozen=True)
class IngestResult:
    digest: str
    tables: dict[str, int]
    already_ingested: bool = False


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
        p.name.removesuffix(".schema.json"): json.loads(p.read_text(encoding="utf-8"))
        for p in sorted(schema_dir().glob("*.schema.json"))
    }
    registry = Registry().with_resources(
        (schema["$id"], Resource.from_contents(schema)) for schema in schemas.values()
    )
    return {
        name: Draft202012Validator(schema, registry=registry, format_checker=FormatChecker())
        for name, schema in schemas.items()
    }


def _reject_constant(value: str) -> Any:
    raise ValueError(f"non-JSON numeric constant: {value}")


def _integer(value: int | float | None) -> int | None:
    """JSON Schema accepts integral floats; drivers need actual integers."""
    if value is None:
        return None
    if type(value) is int or (type(value) is float and value.is_integer()):
        return int(value)
    raise ValueError(f"expected int, got {type(value).__name__}")


class Store:
    """Caller-owned idle connection, tuple rows; never closes it or owns caller work."""

    def __init__(self, conn: Any) -> None:
        self.conn = conn
        self.dialect: Dialect
        if isinstance(conn, sqlite3.Connection):
            self.dialect = "sqlite"
        else:
            try:
                import psycopg
            except ImportError as e:
                raise ValueError(
                    "expected sqlite3.Connection or install traust-contracts[postgres]"
                ) from e
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
        except Exception as e:
            return f"; rollback failed: {_error_detail(e)}"
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
        except Exception as e:
            raise IngestError(
                f"artifact {artifact}: begin transaction: {_error_detail(e)}",
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
        except Exception as e:
            rollback_error = self._rollback()
            raise IngestError(f"storage init: {_error_detail(e)}{rollback_error}") from None

    def ingest(
        self, artifact: str, payload: bytes, meta: Mapping[str, str] | None = None
    ) -> IngestResult:
        """Validate exact bytes, retain evidence and projections atomically, or write nothing."""
        self._idle(artifact, payload)
        validator = None
        try:
            validator = validators().get(artifact) if isinstance(artifact, str) else None
            if validator is None:
                raise IngestError("unknown artifact schema")
            if not isinstance(payload, bytes):
                raise IngestError("payload must be bytes")
            document = json.loads(payload, parse_constant=_reject_constant)
            validator.validate(document)
        except Exception as e:
            label = artifact if validator is not None else "<unknown>"
            raise IngestError(
                f"artifact {label}: validation: {_error_detail(e)}",
                artifact=artifact,
                payload=payload,
            ) from None
        digest = hashlib.sha256(payload).hexdigest()
        self._begin(artifact, payload)
        context = f"artifact {artifact}"
        try:
            if self.dialect == "postgres":
                self._execute(
                    query(self.dialect, "artifact.lock.sql"),
                    {"lock_key": int.from_bytes(bytes.fromhex(digest)[:8], signed=True)},
                )
            existing = self._execute(
                query(self.dialect, "artifact.exists.sql"), {"digest": digest}
            ).fetchone()
            if existing:
                self.conn.execute("COMMIT")
                return IngestResult(digest, {}, already_ingested=True)
            context = f"artifact {artifact}, table artifact, column layer_id, row 0"
            layer_id = (meta or {}).get("layer_id")
            if layer_id is None:
                raise IngestError("required value missing or null")
            if not isinstance(layer_id, str):
                raise IngestError("expected string")
            context = f"artifact {artifact}, table artifact, column project_id, row 0"
            project_id = (meta or {}).get("project_id", "local")
            if project_id is None:
                raise IngestError("required value missing or null")
            if not isinstance(project_id, str):
                raise IngestError("expected string")
            context = f"artifact {artifact}, table artifact, row 0"
            self._execute(
                query(self.dialect, "artifact.upsert.sql"),
                {
                    "digest": digest,
                    "name": artifact,
                    "layer_id": layer_id,
                    "project_id": project_id,
                    "payload": payload,
                    "ingested_at": datetime.now(UTC).isoformat(),
                },
            )
            counts = {"artifact": 1}
            # Schemas validate fields and enums; projections only normalize integers and JSON.
            if artifact == "layer":
                context = f"artifact {artifact}, table layer_metadata, row 0"
                metadata = document["metadata"]
                self._execute(
                    query(self.dialect, "layer_metadata.upsert.sql"),
                    {
                        "layer_id": layer_id,
                        "project_id": project_id,
                        "repo": metadata.get("repository"),
                        "created_at": metadata.get("created"),
                        "merkle_root": metadata.get("merkle_root"),
                        "merkle_epoch": _integer(metadata.get("merkle_epoch")),
                        "artifact_digest": digest,
                    },
                )
                counts["layer_metadata"] = 1
            elif artifact == "vuln-findings":
                counts["finding"] = 0
                for index, finding in enumerate(document["findings"]):
                    context = f"artifact {artifact}, table finding, row {index}"
                    self._execute(
                        query(self.dialect, "finding.upsert.sql"),
                        {
                            "layer_id": layer_id,
                            "target": document["target"],
                            "scanned_at": document["scanned_at"],
                            "finding_id": finding["id"],
                            "title": finding["title"],
                            "severity": finding["severity"],
                            "description": finding["description"],
                            "category": finding.get("category"),
                            "file": finding["file"],
                            "line": _integer(finding.get("line")),
                            "cwe": finding.get("cwe"),
                            "recommendation": finding["recommendation"],
                            "confidence": finding["confidence"],
                            "artifact_digest": digest,
                        },
                    )
                    counts["finding"] += 1
            elif artifact == "triage":
                counts["triage_verdict"] = 0
                for index, finding in enumerate(document["findings"]):
                    context = f"artifact {artifact}, table triage_verdict, row {index}"
                    votes = finding.get("vote_breakdown")
                    self._execute(
                        query(self.dialect, "triage_verdict.upsert.sql"),
                        {
                            "layer_id": layer_id,
                            "triage_completed": document["triage_completed"],
                            "finding_id": finding["id"],
                            "source_finding_id": finding.get("orig_id"),
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
                            "artifact_digest": digest,
                        },
                    )
                    counts["triage_verdict"] += 1
            else:
                table, fields = ONE_ROW_PROJECTIONS[artifact]
                context = f"artifact {artifact}, table {table}, row 0"
                values: dict[str, SQLValue] = {
                    "layer_id": layer_id,
                    "project_id": project_id,
                    "artifact_digest": digest,
                }
                for name, kind in fields:
                    value = document.get(name)
                    if kind == "json" and value is not None:
                        value = json.dumps(
                            value, ensure_ascii=False, separators=(",", ":"), allow_nan=False
                        )
                    elif kind == "integer":
                        value = _integer(value)
                    values[name] = value
                self._execute(query(self.dialect, f"{table}.upsert.sql"), values)
                counts[table] = 1
            self.conn.execute("COMMIT")
            return IngestResult(digest, counts)
        except Exception as e:
            rollback_error = self._rollback()
            raise IngestError(
                f"{context}: {_error_detail(e)}{rollback_error}", artifact=artifact, payload=payload
            ) from None
