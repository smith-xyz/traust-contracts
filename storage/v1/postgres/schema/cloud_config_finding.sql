-- Per-finding projection of a cloud-config findings-current report.
--
-- The cloud-config analogue of report_finding, and needed for the same
-- reason: cloud-config-findings-current is a ONE-ROW projection, so its
-- findings lived only inside a JSON column. Measured 2026-09-19 -- 91 repos
-- carrying 2,592 findings were absent from every storage/v1 dashboard query
-- while being present in findings.db, which is the entire v_open shortfall
-- attributable to this family.
--
-- Carries the IaC columns a policy finding is actually cut by: check_id is
-- what separates two findings on one resource, and framework/provider are
-- how a compliance view slices them.
CREATE TABLE IF NOT EXISTS traust_storage.cloud_config_finding (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    finding_id TEXT NOT NULL,
    title TEXT,
    severity TEXT,
    fingerprint TEXT,
    validation_status TEXT,
    check_id TEXT,
    framework TEXT,
    provider TEXT,
    status TEXT,
    scanner_severity TEXT,
    validity TEXT,
    resolution TEXT,
    assurance TEXT,
    last_updated TEXT,
    conflict INTEGER,
    fp_overridden INTEGER,
    fp_reassertion_blocked INTEGER,
    refuted_awaiting_signoff INTEGER,
    severity_override JSONB,
    PRIMARY KEY (binding_id, finding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES traust_storage.artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_cloud_config_finding_fingerprint
    ON traust_storage.cloud_config_finding (fingerprint)
    WHERE fingerprint IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_cloud_config_finding_disposition
    ON traust_storage.cloud_config_finding (validity, resolution);

CREATE INDEX IF NOT EXISTS idx_cloud_config_finding_check
    ON traust_storage.cloud_config_finding (check_id);
