CREATE TABLE IF NOT EXISTS fleet_fix (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    id TEXT NOT NULL,
    pattern_ref TEXT NOT NULL,
    description TEXT NOT NULL,
    matcher TEXT NOT NULL CHECK (matcher IS NULL OR json_valid(matcher)),
    resolver TEXT CHECK (resolver IS NULL OR json_valid(resolver)),
    rewrite TEXT NOT NULL CHECK (rewrite IS NULL OR json_valid(rewrite)),
    guards TEXT NOT NULL CHECK (guards IS NULL OR json_valid(guards)),
    tests TEXT NOT NULL CHECK (tests IS NULL OR json_valid(tests))
);

CREATE INDEX IF NOT EXISTS idx_fleet_fix_project ON fleet_fix (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_fleet_fix_artifact ON fleet_fix (artifact_digest);
