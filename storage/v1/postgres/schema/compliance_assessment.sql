CREATE TABLE IF NOT EXISTS traust_storage.compliance_assessment (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    metadata JSONB NOT NULL,
    coverage JSONB NOT NULL,
    results JSONB NOT NULL,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES traust_storage.artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_compliance_assessment_artifact ON traust_storage.compliance_assessment (artifact_digest);
