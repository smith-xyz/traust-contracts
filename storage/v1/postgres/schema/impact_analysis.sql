CREATE TABLE IF NOT EXISTS impact_analysis (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    metadata JSONB NOT NULL,
    summary JSONB NOT NULL,
    repos JSONB NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_impact_analysis_project ON impact_analysis (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_impact_analysis_artifact ON impact_analysis (artifact_digest);
