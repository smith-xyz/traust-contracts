INSERT INTO traust_storage.benchmark_target (
    binding_id,
    artifact_digest,
    version,
    updated,
    targets
) VALUES (
    %(binding_id)s,
    %(artifact_digest)s,
    %(version)s,
    %(updated)s,
    %(targets)s
)
ON CONFLICT (binding_id) DO NOTHING;
