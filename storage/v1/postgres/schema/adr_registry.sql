CREATE TABLE IF NOT EXISTS traust_storage.adr_registry (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    version BIGINT NOT NULL,
    note TEXT,
    registers JSONB NOT NULL,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES traust_storage.artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_adr_registry_artifact ON traust_storage.adr_registry (artifact_digest);
