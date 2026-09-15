CREATE TABLE IF NOT EXISTS compliance_scope (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    version INTEGER NOT NULL,
    updated TEXT NOT NULL,
    boundaries TEXT NOT NULL CHECK (boundaries IS NULL OR json_valid(boundaries))
);

CREATE INDEX IF NOT EXISTS idx_compliance_scope_project ON compliance_scope (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_compliance_scope_artifact ON compliance_scope (artifact_digest);
