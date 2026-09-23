CREATE TABLE IF NOT EXISTS refuted_register (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    source TEXT NOT NULL,
    sources TEXT,
    generated_at TEXT NOT NULL,
    entries TEXT NOT NULL,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);
