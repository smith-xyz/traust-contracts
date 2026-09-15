CREATE TABLE IF NOT EXISTS cloud_config_audit (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    title TEXT NOT NULL,
    metadata JSONB NOT NULL,
    summary JSONB NOT NULL,
    findings JSONB NOT NULL,
    gaps JSONB
);

CREATE INDEX IF NOT EXISTS idx_cloud_config_audit_project ON cloud_config_audit (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_cloud_config_audit_artifact ON cloud_config_audit (artifact_digest);
