CREATE TABLE IF NOT EXISTS traust_storage.sla_policy (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    policy_name TEXT NOT NULL,
    source JSONB NOT NULL,
    severity_mapping JSONB NOT NULL,
    clock_start TEXT,
    profiles JSONB NOT NULL,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES traust_storage.artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_sla_policy_artifact ON traust_storage.sla_policy (artifact_digest);
