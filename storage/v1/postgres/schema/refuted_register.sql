CREATE TABLE IF NOT EXISTS traust_storage.refuted_register (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    source TEXT NOT NULL,
    sources JSONB,
    generated_at TEXT NOT NULL,
    entries JSONB NOT NULL,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES traust_storage.artifact_binding(binding_id, artifact_digest)
);
