INSERT INTO pqc_facts (
    binding_id,
    artifact_digest,
    artifact,
    repository,
    stamps,
    coverage,
    summary,
    facts
) VALUES (
    :binding_id,
    :artifact_digest,
    :artifact,
    :repository,
    :stamps,
    :coverage,
    :summary,
    :facts
)
ON CONFLICT (binding_id) DO NOTHING;
