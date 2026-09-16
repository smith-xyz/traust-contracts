INSERT INTO compliance_assessment (
    binding_id,
    artifact_digest,
    metadata,
    coverage,
    results
) VALUES (
    :binding_id,
    :artifact_digest,
    :metadata,
    :coverage,
    :results
)
ON CONFLICT (binding_id) DO NOTHING;
