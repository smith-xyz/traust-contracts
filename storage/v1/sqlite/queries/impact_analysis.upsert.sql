INSERT INTO impact_analysis (
    binding_id,
    artifact_digest,
    metadata,
    summary,
    repos
) VALUES (
    :binding_id,
    :artifact_digest,
    :metadata,
    :summary,
    :repos
)
ON CONFLICT (binding_id) DO NOTHING;
