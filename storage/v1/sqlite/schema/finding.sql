CREATE TABLE IF NOT EXISTS finding (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    finding_id TEXT NOT NULL,
    target TEXT NOT NULL,
    scanned_at TEXT NOT NULL,
    title TEXT NOT NULL,
    severity TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT,
    file TEXT NOT NULL,
    line INTEGER,
    cwe TEXT,
    recommendation TEXT NOT NULL,
    confidence REAL NOT NULL,
    PRIMARY KEY (binding_id, finding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_finding_severity
    ON finding (severity);
