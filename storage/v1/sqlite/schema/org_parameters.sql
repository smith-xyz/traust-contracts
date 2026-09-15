CREATE TABLE IF NOT EXISTS org_parameters (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    version INTEGER NOT NULL,
    declared_by TEXT NOT NULL,
    declared_on TEXT,
    note TEXT,
    parameters TEXT NOT NULL CHECK (parameters IS NULL OR json_valid(parameters))
);

CREATE INDEX IF NOT EXISTS idx_org_parameters_project ON org_parameters (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_org_parameters_artifact ON org_parameters (artifact_digest);
