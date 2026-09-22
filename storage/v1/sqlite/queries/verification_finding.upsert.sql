INSERT INTO verification_finding (
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
    :binding_id,
    :artifact_digest,
    :original_id,
    :original_title,
    :original_severity,
    :verdict,
    :remediation_commits,
    :unattributed,
:evidence_explanation,
    :evidence_framework_reference,
    :evidence_original_code,
    :evidence_patched_code,
    :disposition_rationale,
    :residual_risk,
    :residual_severity,
    :cross_repo
)
ON CONFLICT (binding_id, original_id) DO NOTHING;
