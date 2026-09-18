"""Small authored inputs for storage behavior tests, independent of the real sample."""

import json
from typing import Any

FAMILIES = [
    "adapter-result",
    "adr-registry",
    "attack-mapping",
    "benchmark-target",
    "cloud-config-audit",
    "cloud-config-findings-current",
    "compliance-assessment",
    "compliance-mapping",
    "compliance-scope",
    "corpus-registry",
    "doc-variance",
    "fleet-fix",
    "impact-analysis",
    "isolation-review",
    "layer",
    "org-parameters",
    "pqc-blockers",
    "pqc-decision-tree",
    "pqc-facts",
    "pqc-readiness",
    "remediation",
    "report",
    "risk-rating-methodology",
    "sla-policy",
    "triage",
    "validation",
    "verification",
    "vuln-findings",
]
RUN_BOUND = {
    "adapter-result",
    "cloud-config-audit",
    "cloud-config-findings-current",
    "compliance-assessment",
    "doc-variance",
    "pqc-blockers",
    "pqc-facts",
    "pqc-readiness",
    "remediation",
    "report",
    "triage",
    "validation",
    "verification",
    "vuln-findings",
}
PROJECTION_TABLES = {
    **{name: name.replace("-", "_") for name in FAMILIES},
    "layer": "layer_metadata",
    "triage": "triage_verdict",
    "vuln-findings": "finding",
    "corpus-registry": "subject_ownership",
}

# Artifacts that project into a SECOND table beyond their primary one.
# `report` keeps its one-row row (findings stay a faithful JSON column) and
# additionally fans each finding into report_finding so disposition and
# fingerprint are queryable.
SECONDARY_PROJECTION_TABLES = {"report": "report_finding"}


AUTHORED_SAMPLES: dict[str, dict[str, Any]] = {
    # Two subjects on purpose: one owned HEAD audit and one external-bu branch
    # re-audit, so the branch-audit exclusion that every denominator depends on
    # is exercised rather than assumed.
    "corpus-registry": {
        "version": 1,
        "updated": "2026-01-01T00:00:00Z",
        "subjects": [
            {
                "subject_id": "findings/example/repo",
                "tree": "findings",
                "ownership": "owned",
                "business_unit": "Platform Group",
                "label": "platform",
                "product": "example-product",
                "repo_url": "https://example.test/repo",
                "is_branch_audit": False,
            },
            {
                "subject_id": "other/example/repo@release-1.0",
                "tree": "other-findings",
                "ownership": "external-bu",
                "business_unit": "Other Unit",
                "ref": "release-1.0",
                "ref_kind": "branch",
                "is_branch_audit": True,
            },
        ],
    },
    "impact-analysis": {
        "metadata": {
            "cve": "CVE-2026-1",
            "module": "x",
            "vulnerable_range": "x",
            "harness_version": "x",
            "generated_at": "2026-01-01T00:00:00Z",
            "tiers_executed": [],
            "options": {},
        },
        "summary": {
            "repos_in_blast_radius": 0,
            "version_in_range": 0,
            "affected": 0,
            "likely_affected": 0,
            "not_observed": 0,
            "version_not_in_range": 0,
            "not_imported": 0,
            "inconclusive": 0,
        },
        "repos": [],
    },
    "report": {
        "title": "Security audit",
        "metadata": {"date": "2026-01-01", "scope": "xxxxxxxxxx"},
        "executive_summary": {
            "prose": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
            "severity_counts": {
                "critical": 0,
                "high": 0,
                "medium": 0,
                "low": 0,
                "informational": 0,
            },
        },
        "severity_criteria": [
            {"level": "critical", "definition": "xxxxxxxxxxxxxxxxxxxx"},
            {"level": "critical", "definition": "xxxxxxxxxxxxxxxxxxxx"},
            {"level": "critical", "definition": "xxxxxxxxxxxxxxxxxxxx"},
            {"level": "critical", "definition": "xxxxxxxxxxxxxxxxxxxx"},
        ],
        "findings": [],
        "findings_summary": [
            {"severity": "critical", "count": 0, "finding_ids": []},
            {"severity": "critical", "count": 0, "finding_ids": []},
            {"severity": "critical", "count": 0, "finding_ids": []},
            {"severity": "critical", "count": 0, "finding_ids": []},
        ],
        "remediation_roadmap": [{"priority": "x", "action": "xxxxxxxxxx", "addresses": ["x"]}],
    },
    "validation": {
        "title": "Validation report",
        "metadata": {
            "date": "2026-01-01",
            "harness_version": "xxx",
            "scope_binding_mode": "explicit",
            "target_fingerprint": [],
        },
        "source_reports": [{"kind": "security-audit", "path": "x"}],
        "summary": {
            "by_verdict": {
                "confirmed": 0,
                "refuted": 0,
                "inconclusive": 0,
                "blocked_by_scope": 0,
                "not_attempted": 0,
            },
            "by_technique": {},
        },
        "validated_findings": [],
        "attack_chains": [],
        "novel_findings": [],
        "execution_log_ref": "x",
    },
    "risk-rating-methodology": {
        "methodology": "OWASP Risk Rating Methodology",
        "methodology_version": "1.0.0",
        "source": "https://example.test/value",
        "bands": ["critical", "high", "medium", "low", "note"],
        "bucket_thresholds": {"medium_min": 0, "high_min": 4.5},
        "likelihood_factors": {
            "AV": {"N": 0, "A": 0, "L": 0, "P": 0},
            "AC": {"L": 0, "H": 0},
            "PR": {"N": 0, "L": 0, "H": 0},
            "UI": {"N": 0, "R": 0},
        },
        "impact_factors": {
            "C": {"H": 0, "L": 0, "N": 0},
            "I": {"H": 0, "L": 0, "N": 0},
            "A": {"H": 0, "L": 0, "N": 0},
        },
        "matrix": {
            "LOW": {"LOW": "critical", "MEDIUM": "critical", "HIGH": "critical"},
            "MEDIUM": {"LOW": "critical", "MEDIUM": "critical", "HIGH": "critical"},
            "HIGH": {"LOW": "critical", "MEDIUM": "critical", "HIGH": "critical"},
        },
        "fallback": {
            "default_likelihood": 0,
            "severity_impact": {
                "critical": 0,
                "high": 0,
                "medium": 0,
                "low": 0,
                "informational": 0,
            },
        },
    },
    "sla-policy": {
        "policy_name": "x",
        "source": {"name": "x", "retrieved": "2026-01-01"},
        "severity_mapping": {"critical": "critical"},
        "profiles": {"default": {"slas": {}}},
    },
    "pqc-facts": {
        "artifact": "pqc-facts",
        "repository": "x",
        "stamps": {"adapter_version": "x", "pqc_scan_commit": "x", "rules_sha256": "x"},
        "coverage": {
            "assessment_basis": "source",
            "scanned_files": 0,
            "skipped_files": 0,
            "rules_in_pack": 0,
        },
        "summary": {"by_rule": {}, "by_qclass": {}, "by_provenance_hint": {}, "by_path_class": {}},
        "facts": [],
    },
    "compliance-scope": {
        "version": 1,
        "updated": "2026-01-01",
        "boundaries": {
            "scope": {
                "frameworks": ["pci-dss-v4"],
                "resolves_via": "explicit",
                "declared_by": "tester",
                "declared_at": "2026-01-01",
            }
        },
    },
    "benchmark-target": {"version": 1, "updated": "2026-01-01", "targets": []},
    "fleet-fix": {
        "id": "x",
        "pattern_ref": "x",
        "description": "x",
        "matcher": {"kind": "pinned_ref_line", "file_glob": ["x"]},
        "rewrite": {"template": "x"},
        "guards": {},
        "tests": [{"name": "x", "file": "x", "before": "x", "after_contains": ["x"]}],
    },
    "adr-registry": {
        "version": 1,
        "registers": [
            {"name": "x", "repo": "https://example.test/value", "paths": ["x"], "pin": "abcdef0"}
        ],
    },
    "attack-mapping": {
        "mapping_version": "1.0.0",
        "attack_version": "1.0",
        "source": "https://example.test/value",
        "attribution": "MITRE ATT&CK",
        "capability_map": {},
        "category_map": {},
    },
    "pqc-blockers": {
        "artifact": "pqc-blockers",
        "title": "xxxxx",
        "metadata": {"date": "x", "scope": "x", "repository": "x"},
        "executive_summary": {"prose": "x", "severity_counts": {}},
        "severity_criteria": [
            {"level": "critical", "definition": "x"},
            {"level": "critical", "definition": "x"},
            {"level": "critical", "definition": "x"},
            {"level": "critical", "definition": "x"},
        ],
        "findings": [],
        "findings_summary": [
            {"severity": "critical", "count": 0, "finding_ids": []},
            {"severity": "critical", "count": 0, "finding_ids": []},
            {"severity": "critical", "count": 0, "finding_ids": []},
            {"severity": "critical", "count": 0, "finding_ids": []},
        ],
        "remediation_roadmap": [{"priority": "x", "action": "x", "addresses": []}],
    },
    "compliance-assessment": {
        "metadata": {
            "artifact": "compliance-assessment",
            "harness_version": "x",
            "target": {"kind": "product"},
            "frameworks": [{"id": "nist-800-53-rev5"}],
            "registry_hash": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            "generated_at": "x",
        },
        "coverage": {
            "nist-800-53-rev5": {
                "total_in_scope": 0,
                "deterministic": 0,
                "evidence_review": 0,
                "organizational": 0,
                "satisfied": 0,
                "not_satisfied": 0,
                "not_assessed": 0,
                "not_applicable": 0,
            }
        },
        "results": [],
    },
    "cloud-config-audit": {
        "title": "x",
        "metadata": {
            "target": "x",
            "assessment_mode": "declared",
            "harness_version": "x",
            "checkov_version": "x",
            "facts_ref": "x",
            "facts_snapshot_id": "aaaaaaaaaaaaaaaa",
            "deterministic_steps": [{"tool": "x", "invocation": "x"}],
        },
        "summary": {
            "facts_total": 0,
            "confirmed": 0,
            "suppressed": 0,
            "needs_review": 0,
            "gaps": 0,
        },
        "findings": [],
    },
    "pqc-readiness": {
        "title": "x",
        "metadata": {
            "repository": "https://example.test/repo",
            "assessment_basis": "source",
            "tool": {"pqc_scan_commit": "x", "rules_sha256": "x"},
        },
        "scores": {
            "VULN": {"score": 0, "checks": []},
            "AGIL": {"score": 0, "checks": []},
            "PQCA": {"score": 0, "checks": []},
            "HNDL": {"score": 0, "checks": []},
            "overall": 0,
        },
        "flags": {
            "has_2030_clock_items": False,
            "hndl_priority": False,
            "runtime_verification_required": False,
        },
        "provenance_summary": {"counts": {}, "dominant": "inherited-platform"},
    },
    "isolation-review": {
        "title": "x",
        "metadata": {
            "service": "x",
            "repos": ["x"],
            "graph_ref": "x",
            "harness_version": "x",
            "reviewed_at": "x",
        },
        "interfaces": [],
        "gaps": [],
        "posture": {"overall": "strong", "summary": "x"},
    },
    "verification": {
        "title": "Verification report",
        "metadata": {
            "date": "2026-01-01",
            "harness_version": "0.1.0",
            "original_report": "x",
            "original_commit": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            "patched_commit": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
            "repository": "https://example.test/value",
        },
        "summary": {
            "total_findings": 1,
            "by_verdict": {
                "resolved": 0,
                "partially_resolved": 0,
                "unresolved": 0,
                "new_approach": 0,
                "regression": 0,
                "false_positive": 0,
                "risk_accepted": 0,
            },
            "regressions": 0,
        },
        "verified_findings": [
            {
                "original_id": "x",
                "original_title": "xxxxx",
                "original_severity": "critical",
                "verdict": "resolved",
                "remediation_commits": [],
                "unattributed": False,
                "evidence": {
                    "explanation": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
                    "framework_reference": "xxx",
                },
            }
        ],
        "regressions": [],
        "commit_timeline": [],
    },
    "adapter-result": {
        "target": "x",
        "scanned_at": "xxxxxxxxxx",
        "metadata": {"tool": "x"},
        "findings": [],
    },
    "org-parameters": {
        "version": 1,
        "declared_by": "x",
        "parameters": {"sample": {"value": "x", "controls": ["control"]}},
    },
    "compliance-mapping": {
        "version": 1,
        "controls": [
            {
                "framework": "nist-800-53-rev5",
                "control_id": "x",
                "classification": "deterministic",
                "checks": ["chk-x"],
            }
        ],
        "checks": [
            {"id": "chk-x", "collector": "x", "assertion": {"path": "x", "operator": "exists"}}
        ],
    },
    "cloud-config-findings-current": {
        "title": "Example — Cumulative Findings Status",
        "metadata": {
            "target": "x",
            "assessment_mode": "declared",
            "harness_version": "x",
            "checkov_version": "x",
            "facts_ref": "x",
            "facts_snapshot_id": "aaaaaaaaaaaaaaaa",
            "deterministic_steps": [{"tool": "x", "invocation": "x"}],
            "additional": {
                "cumulative": {
                    "source_audit": "x-cloud-config-audit.json",
                    "layer": "x",
                    "generated_at": "x",
                }
            },
            "date": "2026-01-01",
        },
        "summary": {
            "facts_total": 0,
            "confirmed": 0,
            "suppressed": 0,
            "needs_review": 0,
            "gaps": 0,
        },
        "findings": [],
        "disposition_summary": {
            "layer_ref": "x",
            "generated_at": "x",
            "by_resolution": {
                "open": 0,
                "fix_in_progress": 0,
                "resolved": 0,
                "partially_resolved": 0,
                "risk_accepted": 0,
                "regression_introduced": 0,
            },
            "by_validity": {
                "confirmed": 0,
                "corrected": 0,
                "false_positive": 0,
                "not_verified": 0,
                "hardening": 0,
            },
            "severity_overrides": [],
            "conflicts": [],
            "needs_review_count": 0,
        },
    },
    "pqc-decision-tree": {
        "tree_version": "1.0.0",
        "provenance_tree": {
            "rules": [
                {"provenance": "inherited-platform", "when": "xxxxxxxxxx"},
                {"provenance": "inherited-platform", "when": "xxxxxxxxxx"},
                {"provenance": "inherited-platform", "when": "xxxxxxxxxx"},
                {"provenance": "inherited-platform", "when": "xxxxxxxxxx"},
                {"provenance": "inherited-platform", "when": "xxxxxxxxxx"},
                {"provenance": "inherited-platform", "when": "xxxxxxxxxx"},
                {"provenance": "inherited-platform", "when": "xxxxxxxxxx"},
            ]
        },
        "remediation_effort": {
            "rules": [
                {"effort": "trivial", "when": "xxxxxxxxxx"},
                {"effort": "trivial", "when": "xxxxxxxxxx"},
                {"effort": "trivial", "when": "xxxxxxxxxx"},
                {"effort": "trivial", "when": "xxxxxxxxxx"},
            ],
            "classes": ["trivial", "moderate", "significant", "blocked-external"],
        },
        "readiness_buckets": {
            "score_ready_min": 0,
            "score_partial_min": 0,
            "rules": [
                {"bucket": "ready", "when": "xxxxxxxxxx"},
                {"bucket": "ready", "when": "xxxxxxxxxx"},
                {"bucket": "ready", "when": "xxxxxxxxxx"},
                {"bucket": "ready", "when": "xxxxxxxxxx"},
                {"bucket": "ready", "when": "xxxxxxxxxx"},
            ],
            "buckets": ["ready", "partial", "not-ready", "blocked-external", "not-applicable"],
        },
        "tls_control_crosswalk": {
            "app-controlled": ["inherited-platform"],
            "infra-controlled": ["inherited-platform"],
            "vendor-controlled": ["inherited-platform"],
        },
        "fips_interaction": {
            "rules": [
                {"verdict": "blocked-by-provider-version", "when": "xxxxxxxxxx"},
                {"verdict": "blocked-by-provider-version", "when": "xxxxxxxxxx"},
                {"verdict": "blocked-by-provider-version", "when": "xxxxxxxxxx"},
            ]
        },
        "pqc_classification_map": {},
    },
    "remediation": {
        "title": "Remediation report",
        "metadata": {
            "date": "2026-01-01",
            "harness_version": "0.1.0",
            "logical_product": "x",
            "repository": "https://example.test/value",
        },
        "source_findings": [
            {
                "finding_ref": "xxx",
                "title": "xxxxx",
                "severity": "critical",
                "cwes": ["CWE-1"],
                "locations": [{"path": "x"}],
            }
        ],
        "fork": {
            "url": "https://example.test/value",
            "visibility": "private",
            "base_ref": "x",
            "fix_branch": "x",
        },
        "patch": {
            "strategy": "input-validation",
            "rationale": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
            "files_changed": [{"path": "x", "change_type": "modified"}],
            "diffstat": {"files": 1, "additions": 0, "deletions": 0},
        },
        "checks": [{"name": "x", "command": "x", "outcome": "pass"}],
        "summary": {"status": "candidate", "checks_passed": 0, "checks_total": 1},
    },
    "doc-variance": {
        "metadata": {
            "repository": "https://example.test/value",
            "created": "2026-01-01T00:00:00Z",
            "harness_version": "x",
        },
        "records": [],
    },
}


def sample(name: str) -> tuple[bytes, dict[str, str]]:
    if name == "layer":
        document = {
            "metadata": {
                "audit_report": "audit.json",
                "repository": "https://example.test/repo",
                "created": "2026-01-01T00:00:00Z",
                "harness_version": "0.1.0",
            },
            "events": [],
            "needs_review": [],
        }
    elif name == "vuln-findings":
        document = {
            "target": "example/repo",
            "scanned_at": "2026-01-01T00:00:00Z",
            "focus_areas": ["authorization"],
            "metadata": {
                "repo": "repo",
                "repo_slug": "REPO",
                "scanned_ref": "abcdef0",
                "harness_version": "0.1.0",
                "baseline": None,
                "baseline_findings": 0,
            },
            "findings": [
                {
                    "id": "REPO-abcdef0-001",
                    "file": "auth.py",
                    "line": 1,
                    "category": "auth-bypass",
                    "severity": "high",
                    "confidence": 0.9,
                    "title": "Missing authorization check",
                    "description": "An untrusted caller can access another user's private records.",
                    "recommendation": "Check ownership before returning the requested record.",
                },
                {
                    "id": "REPO-abcdef0-002",
                    "file": "debug.py",
                    "line": None,
                    "category": "information-disclosure",
                    "severity": "low",
                    "confidence": 0.5,
                    "title": "Verbose debug information",
                    "description": (
                        "Debug output includes internal paths in an unauthenticated response."
                    ),
                    "recommendation": "Disable debug output in the production configuration.",
                },
            ],
            "summary": {
                "total": 2,
                "critical": 0,
                "high": 1,
                "medium": 0,
                "low": 1,
                "informational": 0,
                "known": 0,
                "low_confidence": 0,
            },
        }
    elif name == "triage":
        document = {
            "triage_completed": "2026-01-02",
            "triage_context": {
                "environment": "Synthetic test environment",
                "votes_per_finding": 1,
                "repo": "repo",
                "harness_version": "0.1.0",
            },
            "summary": {
                "input_count": 1,
                "true_positives": 1,
                "hardening": 0,
                "false_positives": 0,
                "undetermined": 0,
                "duplicates": 0,
                "by_severity": {"critical": 0, "high": 1, "medium": 0, "low": 0},
            },
            "findings": [
                {
                    "id": "f001",
                    "title": "Confirmed authorization issue",
                    "verdict": "true_positive",
                    "severity": "high",
                    "rationale": "Confirmed with a second account; café test.",
                    "vote_breakdown": {
                        "true_positive": 1,
                        "hardening": 0,
                        "false_positive": 0,
                        "cannot_verify": 0,
                    },
                }
            ],
        }
    elif name in AUTHORED_SAMPLES:
        document = AUTHORED_SAMPLES[name]
    else:
        raise ValueError(f"unknown test sample: {name}")
    return encode(document), {"layer_id": "L-test"}


def encode(document: Any) -> bytes:
    return json.dumps(document).encode()
