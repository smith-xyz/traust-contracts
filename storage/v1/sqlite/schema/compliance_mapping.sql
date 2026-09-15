CREATE TABLE IF NOT EXISTS compliance_mapping (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    version INTEGER NOT NULL,
    note TEXT,
    controls TEXT NOT NULL CHECK (controls IS NULL OR json_valid(controls)),
    checks TEXT NOT NULL CHECK (checks IS NULL OR json_valid(checks))
);

CREATE INDEX IF NOT EXISTS idx_compliance_mapping_project ON compliance_mapping (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_compliance_mapping_artifact ON compliance_mapping (artifact_digest);
