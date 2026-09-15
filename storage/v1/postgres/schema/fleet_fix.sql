CREATE TABLE IF NOT EXISTS fleet_fix (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    id TEXT NOT NULL,
    pattern_ref TEXT NOT NULL,
    description TEXT NOT NULL,
    matcher JSONB NOT NULL,
    resolver JSONB,
    rewrite JSONB NOT NULL,
    guards JSONB NOT NULL,
    tests JSONB NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_fleet_fix_project ON fleet_fix (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_fleet_fix_artifact ON fleet_fix (artifact_digest);
