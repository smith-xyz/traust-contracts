INSERT INTO traust_storage.sla_policy (
    binding_id,
    artifact_digest,
    policy_name,
    source,
    severity_mapping,
    clock_start,
    profiles
) VALUES (
    %(binding_id)s,
    %(artifact_digest)s,
    %(policy_name)s,
    %(source)s,
    %(severity_mapping)s,
    %(clock_start)s,
    %(profiles)s
)
ON CONFLICT (binding_id) DO NOTHING;
