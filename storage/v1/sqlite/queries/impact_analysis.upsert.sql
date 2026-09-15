INSERT INTO impact_analysis (
    layer_id,
    project_id,
    artifact_digest,
    metadata,
    summary,
    repos
) VALUES (
    :layer_id,
    :project_id,
    :artifact_digest,
    :metadata,
    :summary,
    :repos
)
ON CONFLICT (layer_id) DO UPDATE SET
    project_id = excluded.project_id,
    artifact_digest = excluded.artifact_digest,
    metadata = excluded.metadata,
    summary = excluded.summary,
    repos = excluded.repos;
