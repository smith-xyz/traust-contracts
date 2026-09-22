INSERT INTO traust_storage.verification_finding (
    binding_id,
    artifact_digest,
    original_id,
    original_title,
    original_severity,
    verdict,
    remediation_commits,
    unattributed,
evidence_explanation,
    evidence_framework_reference,
    evidence_original_code,
    evidence_patched_code,
    disposition_rationale,
    residual_risk,
    residual_severity,
    cross_repo
)
VALUES (
    %(binding_id)s,
    %(artifact_digest)s,
    %(original_id)s,
    %(original_title)s,
    %(original_severity)s,
    %(verdict)s,
    %(remediation_commits)s,
    %(unattributed)s,
%(evidence_explanation)s,
    %(evidence_framework_reference)s,
    %(evidence_original_code)s,
    %(evidence_patched_code)s,
    %(disposition_rationale)s,
    %(residual_risk)s,
    %(residual_severity)s,
    %(cross_repo)s
)
ON CONFLICT (binding_id, original_id) DO NOTHING;
