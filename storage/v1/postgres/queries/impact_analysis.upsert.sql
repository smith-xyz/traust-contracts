INSERT INTO impact_analysis (
    binding_id,
    artifact_digest,
    metadata,
    summary,
    repos
) VALUES (
    %(binding_id)s,
    %(artifact_digest)s,
    %(metadata)s,
    %(summary)s,
    %(repos)s
)
ON CONFLICT (binding_id) DO NOTHING;
