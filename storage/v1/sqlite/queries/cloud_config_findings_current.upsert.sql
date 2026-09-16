INSERT INTO cloud_config_findings_current (
    binding_id,
    artifact_digest,
    title,
    metadata,
    summary,
    findings,
    gaps,
    disposition_summary
) VALUES (
    :binding_id,
    :artifact_digest,
    :title,
    :metadata,
    :summary,
    :findings,
    :gaps,
    :disposition_summary
)
ON CONFLICT (binding_id) DO NOTHING;
