INSERT INTO sla_policy (
    layer_id,
    project_id,
    artifact_digest,
    policy_name,
    source,
    severity_mapping,
    clock_start,
    profiles
) VALUES (
    :layer_id,
    :project_id,
    :artifact_digest,
    :policy_name,
    :source,
    :severity_mapping,
    :clock_start,
    :profiles
)
ON CONFLICT (layer_id) DO UPDATE SET
    project_id = excluded.project_id,
    artifact_digest = excluded.artifact_digest,
    policy_name = excluded.policy_name,
    source = excluded.source,
    severity_mapping = excluded.severity_mapping,
    clock_start = excluded.clock_start,
    profiles = excluded.profiles;
