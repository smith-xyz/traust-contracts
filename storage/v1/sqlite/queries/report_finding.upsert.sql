INSERT INTO report_finding (
    binding_id,
    artifact_digest,
    finding_id,
    title,
    severity,
    fingerprint,
    validation_status,
    validity,
    resolution,
    assurance,
    last_updated,
    conflict,
    fp_overridden,
    fp_reassertion_blocked,
    refuted_awaiting_signoff,
    severity_override
)
VALUES (
    :binding_id,
    :artifact_digest,
    :finding_id,
    :title,
    :severity,
    :fingerprint,
    :validation_status,
    :validity,
    :resolution,
    :assurance,
    :last_updated,
    :conflict,
    :fp_overridden,
    :fp_reassertion_blocked,
    :refuted_awaiting_signoff,
    :severity_override
)
ON CONFLICT (binding_id, finding_id) DO NOTHING;
