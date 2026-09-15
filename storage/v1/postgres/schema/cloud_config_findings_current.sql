CREATE TABLE IF NOT EXISTS cloud_config_findings_current (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    title TEXT NOT NULL,
    metadata JSONB NOT NULL,
    summary JSONB NOT NULL,
    findings JSONB NOT NULL,
    gaps JSONB,
    disposition_summary JSONB NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_cloud_config_findings_current_project ON cloud_config_findings_current (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_cloud_config_findings_current_artifact ON cloud_config_findings_current (artifact_digest);
