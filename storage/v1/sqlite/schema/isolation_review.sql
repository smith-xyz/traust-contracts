CREATE TABLE IF NOT EXISTS isolation_review (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    title TEXT NOT NULL,
    metadata TEXT NOT NULL CHECK (metadata IS NULL OR json_valid(metadata)),
    interfaces TEXT NOT NULL CHECK (interfaces IS NULL OR json_valid(interfaces)),
    gaps TEXT NOT NULL CHECK (gaps IS NULL OR json_valid(gaps)),
    posture TEXT NOT NULL CHECK (posture IS NULL OR json_valid(posture)),
    notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_isolation_review_project ON isolation_review (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_isolation_review_artifact ON isolation_review (artifact_digest);
