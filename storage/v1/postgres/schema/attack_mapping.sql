CREATE TABLE IF NOT EXISTS attack_mapping (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    mapping_version TEXT NOT NULL,
    attack_version TEXT NOT NULL,
    source TEXT NOT NULL,
    documentation TEXT,
    schema TEXT,
    attribution TEXT NOT NULL,
    capability_map JSONB NOT NULL,
    category_map JSONB NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_attack_mapping_project ON attack_mapping (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_attack_mapping_artifact ON attack_mapping (artifact_digest);
