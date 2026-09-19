INSERT INTO traust_storage.priv_profile (
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
    %(binding_id)s,
    %(artifact_digest)s,
    %(repo)s,
    %(tier)s,
    %(workloads)s,
    %(rbac_rules)s,
    %(rbac_flags)s,
    %(scc_requests)s,
    %(sccs_shipped)s,
    %(namespaces)s,
    %(install_modes)s,
    %(operatorgroups)s,
    %(tier2_required_vs_granted)s,
    %(example_or_test_manifests_excluded)s,
    %(summary)s
)
ON CONFLICT (binding_id) DO NOTHING;
