CREATE TABLE IF NOT EXISTS isolation_review (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    title TEXT NOT NULL,
    metadata JSONB NOT NULL,
    interfaces JSONB NOT NULL,
    gaps JSONB NOT NULL,
    posture JSONB NOT NULL,
    notes TEXT,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_isolation_review_artifact ON isolation_review (artifact_digest);
