CREATE TABLE IF NOT EXISTS adr_registry (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    version INTEGER NOT NULL,
    note TEXT,
    registers TEXT NOT NULL CHECK (registers IS NULL OR json_valid(registers)),
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_adr_registry_artifact ON adr_registry (artifact_digest);
