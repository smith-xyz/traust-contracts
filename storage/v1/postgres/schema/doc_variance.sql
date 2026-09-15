CREATE TABLE IF NOT EXISTS doc_variance (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    metadata JSONB NOT NULL,
    records JSONB NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_doc_variance_project ON doc_variance (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_doc_variance_artifact ON doc_variance (artifact_digest);
