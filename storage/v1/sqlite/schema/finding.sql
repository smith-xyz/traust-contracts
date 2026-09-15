CREATE TABLE IF NOT EXISTS finding (
    layer_id TEXT NOT NULL,
    target TEXT NOT NULL,
    scanned_at TEXT NOT NULL,
    finding_id TEXT NOT NULL,
    title TEXT NOT NULL,
    severity TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT,
    file TEXT NOT NULL,
    line INTEGER,
    cwe TEXT,
    recommendation TEXT NOT NULL,
    confidence REAL NOT NULL,
    artifact_digest TEXT NOT NULL,
    PRIMARY KEY (layer_id, finding_id)
);

CREATE INDEX IF NOT EXISTS idx_finding_artifact
    ON finding (artifact_digest);

CREATE INDEX IF NOT EXISTS idx_finding_severity
    ON finding (layer_id, severity);
