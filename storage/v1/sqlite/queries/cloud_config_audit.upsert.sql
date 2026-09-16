INSERT INTO cloud_config_audit (
    binding_id,
    artifact_digest,
    title,
    metadata,
    summary,
    findings,
    gaps
) VALUES (
    :binding_id,
    :artifact_digest,
    :title,
    :metadata,
    :summary,
    :findings,
    :gaps
)
ON CONFLICT (binding_id) DO NOTHING;
