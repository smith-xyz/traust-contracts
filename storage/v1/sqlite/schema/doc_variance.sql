CREATE TABLE IF NOT EXISTS doc_variance (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    metadata TEXT NOT NULL CHECK (metadata IS NULL OR json_valid(metadata)),
    records TEXT NOT NULL CHECK (records IS NULL OR json_valid(records))
);

CREATE INDEX IF NOT EXISTS idx_doc_variance_project ON doc_variance (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_doc_variance_artifact ON doc_variance (artifact_digest);
