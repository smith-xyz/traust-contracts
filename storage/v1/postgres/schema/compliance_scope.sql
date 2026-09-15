CREATE TABLE IF NOT EXISTS compliance_scope (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    version BIGINT NOT NULL,
    updated TEXT NOT NULL,
    boundaries JSONB NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_compliance_scope_project ON compliance_scope (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_compliance_scope_artifact ON compliance_scope (artifact_digest);
