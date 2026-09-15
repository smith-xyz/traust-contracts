CREATE TABLE IF NOT EXISTS remediation (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    title TEXT NOT NULL,
    metadata JSONB NOT NULL,
    source_findings JSONB NOT NULL,
    fork JSONB NOT NULL,
    patch JSONB NOT NULL,
    checks JSONB NOT NULL,
    revalidation JSONB,
    pull_request JSONB,
    summary JSONB NOT NULL,
    notes TEXT,
    footer TEXT
);

CREATE INDEX IF NOT EXISTS idx_remediation_project ON remediation (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_remediation_artifact ON remediation (artifact_digest);
