CREATE TABLE IF NOT EXISTS adr_registry (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    version INTEGER NOT NULL,
    note TEXT,
    registers TEXT NOT NULL CHECK (registers IS NULL OR json_valid(registers))
);

CREATE INDEX IF NOT EXISTS idx_adr_registry_project ON adr_registry (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_adr_registry_artifact ON adr_registry (artifact_digest);
