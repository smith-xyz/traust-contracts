INSERT INTO traust_storage.cloud_config_audit (
    binding_id,
    artifact_digest,
    title,
    metadata,
    summary,
    findings,
    gaps
) VALUES (
    %(binding_id)s,
    %(artifact_digest)s,
    %(title)s,
    %(metadata)s,
    %(summary)s,
    %(findings)s,
    %(gaps)s
)
ON CONFLICT (binding_id) DO NOTHING;
