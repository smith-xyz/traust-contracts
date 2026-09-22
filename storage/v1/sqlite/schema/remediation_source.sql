-- Per-finding projection of what a remediation set out to fix.
--
-- remediation.source_findings[] links a fix back to the findings that
-- justified it, with the triage confidence and live-validation verdict that
-- were known at the time. In a JSON column it could not be joined to
-- current_finding, so "which open findings already have a fix in flight"
-- had no answer in SQL.
--
-- `validation_verdict` is the state AT REMEDIATION TIME, not now. It is
-- evidence about why the work was started and must not be read as the
-- finding's current disposition, which lives on current_finding.
CREATE TABLE IF NOT EXISTS remediation_source (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    finding_ref TEXT NOT NULL,
    title TEXT,
    severity TEXT,
    cwes TEXT CHECK (cwes IS NULL OR json_valid(cwes)),
    locations TEXT CHECK (locations IS NULL OR json_valid(locations)),
    triage_confidence REAL,
    validation_verdict TEXT,
    audit_report_path TEXT,
    triage_report_path TEXT,
    validation_report_path TEXT,
    PRIMARY KEY (binding_id, finding_ref),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_remediation_source_severity
    ON remediation_source (severity);
