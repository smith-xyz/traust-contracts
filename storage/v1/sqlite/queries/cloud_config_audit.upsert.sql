INSERT INTO cloud_config_audit (
    layer_id,
    project_id,
    artifact_digest,
    title,
    metadata,
    summary,
    findings,
    gaps
) VALUES (
    :layer_id,
    :project_id,
    :artifact_digest,
    :title,
    :metadata,
    :summary,
    :findings,
    :gaps
)
ON CONFLICT (layer_id) DO UPDATE SET
    project_id = excluded.project_id,
    artifact_digest = excluded.artifact_digest,
    title = excluded.title,
    metadata = excluded.metadata,
    summary = excluded.summary,
    findings = excluded.findings,
    gaps = excluded.gaps;
