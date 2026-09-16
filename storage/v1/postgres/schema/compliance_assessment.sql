CREATE TABLE IF NOT EXISTS compliance_assessment (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    metadata JSONB NOT NULL,
    coverage JSONB NOT NULL,
    results JSONB NOT NULL,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_compliance_assessment_artifact ON compliance_assessment (artifact_digest);
