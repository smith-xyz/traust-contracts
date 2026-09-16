CREATE TABLE IF NOT EXISTS compliance_assessment (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    metadata TEXT NOT NULL CHECK (metadata IS NULL OR json_valid(metadata)),
    coverage TEXT NOT NULL CHECK (coverage IS NULL OR json_valid(coverage)),
    results TEXT NOT NULL CHECK (results IS NULL OR json_valid(results)),
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_compliance_assessment_artifact ON compliance_assessment (artifact_digest);
