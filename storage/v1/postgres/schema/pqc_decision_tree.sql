CREATE TABLE IF NOT EXISTS pqc_decision_tree (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    tree_version TEXT NOT NULL,
    plan TEXT,
    schema TEXT,
    provenance_tree JSONB NOT NULL,
    remediation_effort JSONB NOT NULL,
    readiness_buckets JSONB NOT NULL,
    tls_control_crosswalk JSONB NOT NULL,
    fips_interaction JSONB NOT NULL,
    pqc_classification_map JSONB NOT NULL,
    server_side_caveat JSONB,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_pqc_decision_tree_artifact ON pqc_decision_tree (artifact_digest);
