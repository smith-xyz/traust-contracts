-- Per-finding projection of a cumulative report.
--
-- report.findings is an opaque JSON column: the disposition every dashboard
-- filters on (validity, resolution) and the identity every distinct-exposure
-- count needs (fingerprint) were present in the contract but unqueryable.
-- This makes them columns without changing what the schema models.
--
-- One row per finding per report binding. Disposition is optional on the
-- artifact -- it appears only on cumulative reports -- so a finding without
-- one still projects, carrying its identity with NULL disposition.
CREATE TABLE IF NOT EXISTS report_finding (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    finding_id TEXT NOT NULL,
    title TEXT,
    severity TEXT,
    -- Secondary correlation key, never the sole key of a disposition record
    -- (report.schema.json): the scan-scoped finding_id stays primary.
    fingerprint TEXT,
    validation_status TEXT,
    validity TEXT,
    resolution TEXT,
    assurance TEXT,
    last_updated TEXT,
    -- The four flags that carry the two-person rule and the countersign
    -- queue. Dropping them is how a dashboard loses sight of whether an FP
    -- was overridden by execution evidence.
    conflict INTEGER,
    fp_overridden INTEGER,
    fp_reassertion_blocked INTEGER,
    refuted_awaiting_signoff INTEGER,
    severity_override TEXT CHECK (severity_override IS NULL OR json_valid(severity_override)),
    PRIMARY KEY (binding_id, finding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_report_finding_fingerprint
    ON report_finding (fingerprint)
    WHERE fingerprint IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_report_finding_disposition
    ON report_finding (validity, resolution);
