CREATE TABLE IF NOT EXISTS pqc_blockers (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    artifact TEXT NOT NULL,
    title TEXT NOT NULL,
    metadata TEXT NOT NULL CHECK (metadata IS NULL OR json_valid(metadata)),
    executive_summary TEXT NOT NULL CHECK (executive_summary IS NULL OR json_valid(executive_summary)),
    severity_criteria TEXT NOT NULL CHECK (severity_criteria IS NULL OR json_valid(severity_criteria)),
    findings TEXT NOT NULL CHECK (findings IS NULL OR json_valid(findings)),
    findings_summary TEXT NOT NULL CHECK (findings_summary IS NULL OR json_valid(findings_summary)),
    remediation_roadmap TEXT NOT NULL CHECK (remediation_roadmap IS NULL OR json_valid(remediation_roadmap)),
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_pqc_blockers_artifact ON pqc_blockers (artifact_digest);
