-- Per-finding projection of a cloud-config findings-current report.
--
-- The cloud-config analogue of report_finding, and needed for the same
-- reason: cloud-config-findings-current is a ONE-ROW projection, so its
-- findings lived only inside a JSON column. Measured 2026-09-19: a whole
-- class of repos and their findings were absent from every storage/v1
-- dashboard query while being present in findings.db, and that was the
-- entire v_open shortfall attributable to this family.
--
-- Carries the IaC columns a policy finding is actually cut by: check_id is
-- what separates two findings on one resource, and framework/provider are
-- how a compliance view slices them.
CREATE TABLE IF NOT EXISTS cloud_config_finding (
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
    severity_override TEXT CHECK (severity_override IS NULL OR json_valid(severity_override)),
    -- The body and the analytical axes, same omission as
    -- report_finding: a policy finding's `cwe`, `rationale` and
    -- `control_refs` are what a compliance view cuts by.
    rationale TEXT,
    remediation TEXT,
    cwe TEXT,
    control_refs TEXT CHECK (control_refs IS NULL OR json_valid(control_refs)),
    locations TEXT CHECK (locations IS NULL OR json_valid(locations)),
    fact_ids TEXT CHECK (fact_ids IS NULL OR json_valid(fact_ids)),
    external_correlation TEXT CHECK (external_correlation IS NULL OR json_valid(external_correlation)),
    effective_severity TEXT,
    fingerprint_algo TEXT,
    isolation_boundary TEXT,
    isolation_dimensions TEXT CHECK (isolation_dimensions IS NULL OR json_valid(isolation_dimensions)),
    PRIMARY KEY (binding_id, finding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_cloud_config_finding_fingerprint
    ON cloud_config_finding (fingerprint)
    WHERE fingerprint IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_cloud_config_finding_disposition
    ON cloud_config_finding (validity, resolution);

CREATE INDEX IF NOT EXISTS idx_cloud_config_finding_check
    ON cloud_config_finding (check_id);
