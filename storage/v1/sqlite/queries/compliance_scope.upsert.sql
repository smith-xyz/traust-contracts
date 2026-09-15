INSERT INTO compliance_scope (
    layer_id,
    project_id,
    artifact_digest,
    version,
    updated,
    boundaries
) VALUES (
    :layer_id,
    :project_id,
    :artifact_digest,
    :version,
    :updated,
    :boundaries
)
ON CONFLICT (layer_id) DO UPDATE SET
    project_id = excluded.project_id,
    artifact_digest = excluded.artifact_digest,
    version = excluded.version,
    updated = excluded.updated,
    boundaries = excluded.boundaries;
