CREATE TABLE IF NOT EXISTS adapter_result (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    target TEXT NOT NULL,
    scanned_at TEXT NOT NULL,
    metadata JSONB NOT NULL,
    findings JSONB NOT NULL,
    summary JSONB,
    focus_areas JSONB
);

CREATE INDEX IF NOT EXISTS idx_adapter_result_project ON adapter_result (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_adapter_result_artifact ON adapter_result (artifact_digest);
