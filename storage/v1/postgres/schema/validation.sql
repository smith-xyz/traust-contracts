CREATE TABLE IF NOT EXISTS validation (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    title TEXT NOT NULL,
    metadata JSONB NOT NULL,
    source_reports JSONB NOT NULL,
    summary JSONB NOT NULL,
    validated_findings JSONB NOT NULL,
    attack_chains JSONB NOT NULL,
    novel_findings JSONB NOT NULL,
    negative_results JSONB,
    execution_log_ref TEXT NOT NULL,
    execution_log_sha256 TEXT,
    footer TEXT
);

CREATE INDEX IF NOT EXISTS idx_validation_project ON validation (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_validation_artifact ON validation (artifact_digest);
