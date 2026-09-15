CREATE TABLE IF NOT EXISTS sla_policy (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    policy_name TEXT NOT NULL,
    source TEXT NOT NULL CHECK (source IS NULL OR json_valid(source)),
    severity_mapping TEXT NOT NULL CHECK (severity_mapping IS NULL OR json_valid(severity_mapping)),
    clock_start TEXT,
    profiles TEXT NOT NULL CHECK (profiles IS NULL OR json_valid(profiles))
);

CREATE INDEX IF NOT EXISTS idx_sla_policy_project ON sla_policy (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_sla_policy_artifact ON sla_policy (artifact_digest);
