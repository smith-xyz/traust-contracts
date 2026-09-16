INSERT INTO pqc_decision_tree (
    binding_id,
    artifact_digest,
    tree_version,
    plan,
    schema,
    provenance_tree,
    remediation_effort,
    readiness_buckets,
    tls_control_crosswalk,
    fips_interaction,
    pqc_classification_map,
    server_side_caveat
) VALUES (
    :binding_id,
    :artifact_digest,
    :tree_version,
    :plan,
    :schema,
    :provenance_tree,
    :remediation_effort,
    :readiness_buckets,
    :tls_control_crosswalk,
    :fips_interaction,
    :pqc_classification_map,
    :server_side_caveat
)
ON CONFLICT (binding_id) DO NOTHING;
