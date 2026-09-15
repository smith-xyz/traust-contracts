INSERT INTO compliance_assessment (
    layer_id,
    project_id,
    artifact_digest,
    metadata,
    coverage,
    results
) VALUES (
    %(layer_id)s,
    %(project_id)s,
    %(artifact_digest)s,
    %(metadata)s,
    %(coverage)s,
    %(results)s
)
ON CONFLICT (layer_id) DO UPDATE SET
    project_id = excluded.project_id,
    artifact_digest = excluded.artifact_digest,
    metadata = excluded.metadata,
    coverage = excluded.coverage,
    results = excluded.results;
