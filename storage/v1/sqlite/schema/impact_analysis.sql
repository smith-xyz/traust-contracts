CREATE TABLE IF NOT EXISTS impact_analysis (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    metadata TEXT NOT NULL CHECK (metadata IS NULL OR json_valid(metadata)),
    summary TEXT NOT NULL CHECK (summary IS NULL OR json_valid(summary)),
    repos TEXT NOT NULL CHECK (repos IS NULL OR json_valid(repos)),
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_impact_analysis_artifact ON impact_analysis (artifact_digest);
