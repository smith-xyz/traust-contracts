CREATE TABLE IF NOT EXISTS traust_storage.layer_metadata (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    repo TEXT,
    created_at TEXT,
    merkle_root TEXT,
    merkle_epoch BIGINT,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES traust_storage.artifact_binding(binding_id, artifact_digest)
);
