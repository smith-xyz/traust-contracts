CREATE TABLE IF NOT EXISTS impact_analysis (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    metadata TEXT NOT NULL CHECK (metadata IS NULL OR json_valid(metadata)),
    summary TEXT NOT NULL CHECK (summary IS NULL OR json_valid(summary)),
    repos TEXT NOT NULL CHECK (repos IS NULL OR json_valid(repos))
);

CREATE INDEX IF NOT EXISTS idx_impact_analysis_project ON impact_analysis (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_impact_analysis_artifact ON impact_analysis (artifact_digest);
