CREATE TABLE IF NOT EXISTS cloud_config_audit (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    title TEXT NOT NULL,
    metadata TEXT NOT NULL CHECK (metadata IS NULL OR json_valid(metadata)),
    summary TEXT NOT NULL CHECK (summary IS NULL OR json_valid(summary)),
    findings TEXT NOT NULL CHECK (findings IS NULL OR json_valid(findings)),
    gaps TEXT CHECK (gaps IS NULL OR json_valid(gaps))
);

CREATE INDEX IF NOT EXISTS idx_cloud_config_audit_project ON cloud_config_audit (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_cloud_config_audit_artifact ON cloud_config_audit (artifact_digest);
