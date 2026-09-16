CREATE TABLE IF NOT EXISTS impact_analysis (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    metadata JSONB NOT NULL,
    summary JSONB NOT NULL,
    repos JSONB NOT NULL,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_impact_analysis_artifact ON impact_analysis (artifact_digest);
