CREATE TABLE IF NOT EXISTS compliance_assessment (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    metadata JSONB NOT NULL,
    coverage JSONB NOT NULL,
    results JSONB NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_compliance_assessment_project ON compliance_assessment (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_compliance_assessment_artifact ON compliance_assessment (artifact_digest);
