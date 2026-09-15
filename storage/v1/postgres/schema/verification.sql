CREATE TABLE IF NOT EXISTS verification (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    title TEXT NOT NULL,
    metadata JSONB NOT NULL,
    summary JSONB NOT NULL,
    verified_findings JSONB NOT NULL,
    regressions JSONB NOT NULL,
    commit_timeline JSONB NOT NULL,
    recommendations JSONB,
    notes TEXT,
    footer TEXT
);

CREATE INDEX IF NOT EXISTS idx_verification_project ON verification (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_verification_artifact ON verification (artifact_digest);
