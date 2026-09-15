CREATE TABLE IF NOT EXISTS report (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    title TEXT NOT NULL,
    metadata JSONB NOT NULL,
    executive_summary JSONB NOT NULL,
    severity_criteria JSONB NOT NULL,
    findings JSONB NOT NULL,
    findings_summary JSONB NOT NULL,
    remediation_roadmap JSONB NOT NULL,
    dependency_audit JSONB,
    negative_results JSONB,
    asvs_coverage JSONB,
    scanner_correlation JSONB,
    peach_isolation_review JSONB,
    disposition_summary JSONB,
    footer TEXT
);

CREATE INDEX IF NOT EXISTS idx_report_project ON report (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_report_artifact ON report (artifact_digest);
