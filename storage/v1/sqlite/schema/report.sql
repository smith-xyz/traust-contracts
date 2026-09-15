CREATE TABLE IF NOT EXISTS report (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    title TEXT NOT NULL,
    metadata TEXT NOT NULL CHECK (metadata IS NULL OR json_valid(metadata)),
    executive_summary TEXT NOT NULL CHECK (executive_summary IS NULL OR json_valid(executive_summary)),
    severity_criteria TEXT NOT NULL CHECK (severity_criteria IS NULL OR json_valid(severity_criteria)),
    findings TEXT NOT NULL CHECK (findings IS NULL OR json_valid(findings)),
    findings_summary TEXT NOT NULL CHECK (findings_summary IS NULL OR json_valid(findings_summary)),
    remediation_roadmap TEXT NOT NULL CHECK (remediation_roadmap IS NULL OR json_valid(remediation_roadmap)),
    dependency_audit TEXT CHECK (dependency_audit IS NULL OR json_valid(dependency_audit)),
    negative_results TEXT CHECK (negative_results IS NULL OR json_valid(negative_results)),
    asvs_coverage TEXT CHECK (asvs_coverage IS NULL OR json_valid(asvs_coverage)),
    scanner_correlation TEXT CHECK (scanner_correlation IS NULL OR json_valid(scanner_correlation)),
    peach_isolation_review TEXT CHECK (peach_isolation_review IS NULL OR json_valid(peach_isolation_review)),
    disposition_summary TEXT CHECK (disposition_summary IS NULL OR json_valid(disposition_summary)),
    footer TEXT
);

CREATE INDEX IF NOT EXISTS idx_report_project ON report (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_report_artifact ON report (artifact_digest);
