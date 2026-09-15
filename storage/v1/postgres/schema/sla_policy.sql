CREATE TABLE IF NOT EXISTS sla_policy (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    policy_name TEXT NOT NULL,
    source JSONB NOT NULL,
    severity_mapping JSONB NOT NULL,
    clock_start TEXT,
    profiles JSONB NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_sla_policy_project ON sla_policy (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_sla_policy_artifact ON sla_policy (artifact_digest);
