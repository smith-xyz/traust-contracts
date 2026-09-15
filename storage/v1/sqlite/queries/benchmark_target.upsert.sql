INSERT INTO benchmark_target (
    layer_id,
    project_id,
    artifact_digest,
    version,
    updated,
    targets
) VALUES (
    :layer_id,
    :project_id,
    :artifact_digest,
    :version,
    :updated,
    :targets
)
ON CONFLICT (layer_id) DO UPDATE SET
    project_id = excluded.project_id,
    artifact_digest = excluded.artifact_digest,
    version = excluded.version,
    updated = excluded.updated,
    targets = excluded.targets;
