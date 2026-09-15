CREATE TABLE IF NOT EXISTS isolation_review (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    title TEXT NOT NULL,
    metadata JSONB NOT NULL,
    interfaces JSONB NOT NULL,
    gaps JSONB NOT NULL,
    posture JSONB NOT NULL,
    notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_isolation_review_project ON isolation_review (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_isolation_review_artifact ON isolation_review (artifact_digest);
