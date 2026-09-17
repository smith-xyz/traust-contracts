INSERT INTO traust_storage.compliance_assessment (
    binding_id,
    artifact_digest,
    metadata,
    coverage,
    results
) VALUES (
    %(binding_id)s,
    %(artifact_digest)s,
    %(metadata)s,
    %(coverage)s,
    %(results)s
)
ON CONFLICT (binding_id) DO NOTHING;
