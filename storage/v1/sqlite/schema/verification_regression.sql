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
CREATE TABLE IF NOT EXISTS verification_regression (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    regression_id TEXT NOT NULL,
    title TEXT,
    severity TEXT,
    cwes TEXT CHECK (cwes IS NULL OR json_valid(cwes)),
    cvss TEXT CHECK (cvss IS NULL OR json_valid(cvss)),
    locations TEXT CHECK (locations IS NULL OR json_valid(locations)),
    description TEXT,
    remediation TEXT,
    evidence TEXT CHECK (evidence IS NULL OR json_valid(evidence)),
    attack_pattern TEXT,
    category TEXT,
    introduced_by TEXT,
    routed_id TEXT,
    fingerprint TEXT,
    fingerprint_algo TEXT,
    PRIMARY KEY (binding_id, regression_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_verification_regression_severity
    ON verification_regression (severity);

CREATE INDEX IF NOT EXISTS idx_verification_regression_fingerprint
    ON verification_regression (fingerprint);
