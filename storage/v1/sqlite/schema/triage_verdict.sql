CREATE TABLE IF NOT EXISTS triage_verdict (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    finding_id TEXT NOT NULL,
    source_finding_id TEXT,
    triage_completed TEXT NOT NULL,
    verdict TEXT NOT NULL,
    severity TEXT,
    vote_breakdown TEXT,
    rationale TEXT,
    PRIMARY KEY (binding_id, finding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_triage_verdict_source
    ON triage_verdict (source_finding_id, verdict);
