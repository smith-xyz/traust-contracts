CREATE TABLE IF NOT EXISTS layer_metadata (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    repo TEXT,
    created_at TEXT,
    merkle_root TEXT,
    merkle_epoch INTEGER,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);
