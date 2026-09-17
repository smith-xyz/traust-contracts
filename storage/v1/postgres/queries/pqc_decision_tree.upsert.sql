INSERT INTO traust_storage.pqc_decision_tree (
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
    %(binding_id)s,
    %(artifact_digest)s,
    %(tree_version)s,
    %(plan)s,
    %(schema)s,
    %(provenance_tree)s,
    %(remediation_effort)s,
    %(readiness_buckets)s,
    %(tls_control_crosswalk)s,
    %(fips_interaction)s,
    %(pqc_classification_map)s,
    %(server_side_caveat)s
)
ON CONFLICT (binding_id) DO NOTHING;
