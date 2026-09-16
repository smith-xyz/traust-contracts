INSERT INTO sla_policy (
    binding_id,
    artifact_digest,
    policy_name,
    source,
    severity_mapping,
    clock_start,
    profiles
) VALUES (
    :binding_id,
    :artifact_digest,
    :policy_name,
    :source,
    :severity_mapping,
    :clock_start,
    :profiles
)
ON CONFLICT (binding_id) DO NOTHING;
