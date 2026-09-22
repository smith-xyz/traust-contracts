-- Per-regression projection of a remediation verification.
--
-- A regression is a NEW finding the fix introduced, not a restatement of the
-- one it was meant to close, so it carries a finding's full shape --
-- severity, cwes, locations, description, remediation -- and `introduced_by`,
-- the commit that caused it.
--
-- Separate from verification_finding on purpose. Folding the two would make
-- "how many findings did this verification touch" ambiguous, and the
-- regressions are the half a remediation review must not miss.
CREATE TABLE IF NOT EXISTS traust_storage.verification_regression (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    regression_id TEXT NOT NULL,
    title TEXT,
    severity TEXT,
    cwes JSONB,
    cvss JSONB,
    locations JSONB,
    description TEXT,
    remediation TEXT,
    evidence JSONB,
    attack_pattern TEXT,
    category TEXT,
    introduced_by TEXT,
    routed_id TEXT,
    fingerprint TEXT,
    fingerprint_algo TEXT,
    PRIMARY KEY (binding_id, regression_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES traust_storage.artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_verification_regression_severity
    ON traust_storage.verification_regression (severity);

CREATE INDEX IF NOT EXISTS idx_verification_regression_fingerprint
    ON traust_storage.verification_regression (fingerprint);
