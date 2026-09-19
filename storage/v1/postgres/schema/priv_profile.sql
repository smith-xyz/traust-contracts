-- Operator privilege profile: the privilege an operator ASKS FOR.
--
-- DECLARED state, parsed from shipped manifests -- never a live cluster
-- read. "What would this grant if installed", not "what is granted now".
--
-- The nested asks (workloads, rules, SCCs) stay whole in JSON because a
-- least-privilege review reads the actual rule; the columns are the
-- summary a dashboard cuts by, lifted out so it need not open the blob.
CREATE TABLE IF NOT EXISTS traust_storage.priv_profile (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    repo TEXT NOT NULL,
    tier TEXT,
    workload_count INTEGER,
    -- The headline least-privilege number.
    privileged_or_host_workloads INTEGER,
    rbac_rule_count INTEGER,
    -- De-duplicated size of the ask. Rule COUNT inflates with how the
    -- bundle happens to be authored; the triple count does not, which is
    -- why both are kept rather than just the cheaper one.
    distinct_rule_triples INTEGER,
    distinct_cluster_triples INTEGER,
    cluster_scoped_rules INTEGER,
    wildcard_rules INTEGER,
    -- Distinct from an empty scc_requests list: "asked for nothing" and
    -- "we could not tell" must never read the same.
    no_scc_request_recorded INTEGER,
    workloads JSONB,
    rbac_rules JSONB,
    rbac_flags JSONB,
    scc_requests JSONB,
    sccs_shipped JSONB,
    namespaces JSONB,
    install_modes JSONB,
    operatorgroups JSONB,
    tier2_required_vs_granted JSONB,
    example_or_test_manifests_excluded JSONB,
    summary JSONB,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES traust_storage.artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_priv_profile_repo ON traust_storage.priv_profile (repo);
