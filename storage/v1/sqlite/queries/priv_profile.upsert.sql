INSERT INTO priv_profile (
    binding_id,
    artifact_digest,
    repo,
    tier,
    workloads,
    rbac_rules,
    rbac_flags,
    scc_requests,
    sccs_shipped,
    namespaces,
    install_modes,
    operatorgroups,
    tier2_required_vs_granted,
    example_or_test_manifests_excluded,
    summary
)
VALUES (
    :binding_id,
    :artifact_digest,
    :repo,
    :tier,
    :workloads,
    :rbac_rules,
    :rbac_flags,
    :scc_requests,
    :sccs_shipped,
    :namespaces,
    :install_modes,
    :operatorgroups,
    :tier2_required_vs_granted,
    :example_or_test_manifests_excluded,
    :summary
)
ON CONFLICT (binding_id) DO NOTHING;
