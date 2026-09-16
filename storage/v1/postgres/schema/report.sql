CREATE TABLE IF NOT EXISTS report (
    binding_id TEXT NOT NULL,
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
    footer TEXT,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_report_artifact ON report (artifact_digest);
