CREATE TABLE IF NOT EXISTS attack_mapping (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    mapping_version TEXT NOT NULL,
    attack_version TEXT NOT NULL,
    source TEXT NOT NULL,
    documentation TEXT,
    schema TEXT,
    attribution TEXT NOT NULL,
    capability_map JSONB NOT NULL,
    category_map JSONB NOT NULL,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_attack_mapping_artifact ON attack_mapping (artifact_digest);
