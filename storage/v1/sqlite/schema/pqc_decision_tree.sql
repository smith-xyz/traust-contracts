CREATE TABLE IF NOT EXISTS pqc_decision_tree (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    tree_version TEXT NOT NULL,
    plan TEXT,
    schema TEXT,
    provenance_tree TEXT NOT NULL CHECK (provenance_tree IS NULL OR json_valid(provenance_tree)),
    remediation_effort TEXT NOT NULL CHECK (remediation_effort IS NULL OR json_valid(remediation_effort)),
    readiness_buckets TEXT NOT NULL CHECK (readiness_buckets IS NULL OR json_valid(readiness_buckets)),
    tls_control_crosswalk TEXT NOT NULL CHECK (tls_control_crosswalk IS NULL OR json_valid(tls_control_crosswalk)),
    fips_interaction TEXT NOT NULL CHECK (fips_interaction IS NULL OR json_valid(fips_interaction)),
    pqc_classification_map TEXT NOT NULL CHECK (pqc_classification_map IS NULL OR json_valid(pqc_classification_map)),
    server_side_caveat TEXT CHECK (server_side_caveat IS NULL OR json_valid(server_side_caveat))
);

CREATE INDEX IF NOT EXISTS idx_pqc_decision_tree_project ON pqc_decision_tree (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_pqc_decision_tree_artifact ON pqc_decision_tree (artifact_digest);
