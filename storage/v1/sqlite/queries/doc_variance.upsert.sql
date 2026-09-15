INSERT INTO doc_variance (
    layer_id,
    project_id,
    artifact_digest,
    metadata,
    records
) VALUES (
    :layer_id,
    :project_id,
    :artifact_digest,
    :metadata,
    :records
)
ON CONFLICT (layer_id) DO UPDATE SET
    project_id = excluded.project_id,
    artifact_digest = excluded.artifact_digest,
    metadata = excluded.metadata,
    records = excluded.records;
