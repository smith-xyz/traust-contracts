CREATE TABLE IF NOT EXISTS triage_verdict (
    layer_id TEXT NOT NULL,
    triage_completed TEXT NOT NULL,
    finding_id TEXT NOT NULL,
    source_finding_id TEXT,
    verdict TEXT NOT NULL,
    severity TEXT,
    vote_breakdown TEXT,
    rationale TEXT,
    artifact_digest TEXT NOT NULL,
    PRIMARY KEY (layer_id, finding_id)
);

CREATE INDEX IF NOT EXISTS idx_triage_verdict
    ON triage_verdict (layer_id, verdict);

CREATE INDEX IF NOT EXISTS idx_triage_verdict_artifact
    ON triage_verdict (artifact_digest);
