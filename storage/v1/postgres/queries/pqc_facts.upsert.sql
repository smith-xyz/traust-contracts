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
    %(binding_id)s,
    %(artifact_digest)s,
    %(artifact)s,
    %(repository)s,
    %(stamps)s,
    %(coverage)s,
    %(summary)s,
    %(facts)s
)
ON CONFLICT (binding_id) DO NOTHING;
