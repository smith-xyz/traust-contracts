CREATE TABLE IF NOT EXISTS traust_storage.isolation_review (
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
        REFERENCES traust_storage.artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_isolation_review_artifact ON traust_storage.isolation_review (artifact_digest);
