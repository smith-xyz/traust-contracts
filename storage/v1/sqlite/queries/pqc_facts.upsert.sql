INSERT INTO pqc_facts (
    layer_id,
    project_id,
    artifact_digest,
    artifact,
    repository,
    stamps,
    coverage,
    summary,
    facts
) VALUES (
    :layer_id,
    :project_id,
    :artifact_digest,
    :artifact,
    :repository,
    :stamps,
    :coverage,
    :summary,
    :facts
)
ON CONFLICT (layer_id) DO UPDATE SET
    project_id = excluded.project_id,
    artifact_digest = excluded.artifact_digest,
    artifact = excluded.artifact,
    repository = excluded.repository,
    stamps = excluded.stamps,
    coverage = excluded.coverage,
    summary = excluded.summary,
    facts = excluded.facts;
