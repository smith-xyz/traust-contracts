CREATE TABLE IF NOT EXISTS cloud_config_findings_current (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    title TEXT NOT NULL,
    metadata TEXT NOT NULL CHECK (metadata IS NULL OR json_valid(metadata)),
    summary TEXT NOT NULL CHECK (summary IS NULL OR json_valid(summary)),
    findings TEXT NOT NULL CHECK (findings IS NULL OR json_valid(findings)),
    gaps TEXT CHECK (gaps IS NULL OR json_valid(gaps)),
    disposition_summary TEXT NOT NULL CHECK (disposition_summary IS NULL OR json_valid(disposition_summary))
);

CREATE INDEX IF NOT EXISTS idx_cloud_config_findings_current_project ON cloud_config_findings_current (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_cloud_config_findings_current_artifact ON cloud_config_findings_current (artifact_digest);
