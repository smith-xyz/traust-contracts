CREATE TABLE IF NOT EXISTS traust_storage.finding (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    finding_id TEXT NOT NULL,
    target TEXT NOT NULL,
    scanned_at TEXT NOT NULL,
    title TEXT NOT NULL,
    severity TEXT NOT NULL CHECK (severity IN (
        'critical', 'high', 'medium', 'low', 'informational'
    )),
    description TEXT NOT NULL,
    category TEXT,
    file TEXT NOT NULL,
    line BIGINT,
    cwe TEXT,
    recommendation TEXT NOT NULL,
    confidence DOUBLE PRECISION NOT NULL,
    PRIMARY KEY (binding_id, finding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES traust_storage.artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_finding_severity
    ON traust_storage.finding (severity);
