INSERT INTO validation_finding (
    binding_id,
    artifact_digest,
    source_id,
    source_finding_id,
    title,
    claimed_severity,
    surface,
    verdict,
    skip_reason,
    technique,
    observed_impact
)
VALUES (
    :binding_id,
    :artifact_digest,
    :source_id,
    :source_finding_id,
    :title,
    :claimed_severity,
    :surface,
    :verdict,
    :skip_reason,
    :technique,
    :observed_impact
)
ON CONFLICT (binding_id, source_id) DO NOTHING;
