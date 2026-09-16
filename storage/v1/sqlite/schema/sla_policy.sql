CREATE TABLE IF NOT EXISTS sla_policy (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    policy_name TEXT NOT NULL,
    source TEXT NOT NULL CHECK (source IS NULL OR json_valid(source)),
    severity_mapping TEXT NOT NULL CHECK (severity_mapping IS NULL OR json_valid(severity_mapping)),
    clock_start TEXT,
    profiles TEXT NOT NULL CHECK (profiles IS NULL OR json_valid(profiles)),
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_sla_policy_artifact ON sla_policy (artifact_digest);
