-- Operator privilege profile: the privilege an operator ASKS FOR.
--
-- DECLARED state, parsed from shipped manifests -- never a live cluster
-- read. "What would this grant if installed", not "what is granted now".
--
-- Columns mirror the schema's ROOT properties, one per artifact, which is
-- the invariant every one-row projection here holds to. The summary counts
-- a dashboard cuts by live one level down in `summary`, so they are lifted
-- in the operator_privilege VIEW rather than duplicated as columns: two
-- copies of one number is how they drift.
CREATE TABLE IF NOT EXISTS traust_storage.priv_profile (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    repo TEXT NOT NULL,
    tier TEXT,
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
