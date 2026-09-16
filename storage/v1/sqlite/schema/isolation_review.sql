CREATE TABLE IF NOT EXISTS isolation_review (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    title TEXT NOT NULL,
    metadata TEXT NOT NULL CHECK (metadata IS NULL OR json_valid(metadata)),
    interfaces TEXT NOT NULL CHECK (interfaces IS NULL OR json_valid(interfaces)),
    gaps TEXT NOT NULL CHECK (gaps IS NULL OR json_valid(gaps)),
    posture TEXT NOT NULL CHECK (posture IS NULL OR json_valid(posture)),
    notes TEXT,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_isolation_review_artifact ON isolation_review (artifact_digest);
