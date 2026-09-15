CREATE TABLE IF NOT EXISTS pqc_blockers (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    artifact TEXT NOT NULL,
    title TEXT NOT NULL,
    metadata JSONB NOT NULL,
    executive_summary JSONB NOT NULL,
    severity_criteria JSONB NOT NULL,
    findings JSONB NOT NULL,
    findings_summary JSONB NOT NULL,
    remediation_roadmap JSONB NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_pqc_blockers_project ON pqc_blockers (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_pqc_blockers_artifact ON pqc_blockers (artifact_digest);
