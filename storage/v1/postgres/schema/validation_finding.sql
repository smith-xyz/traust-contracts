-- Per-finding projection of a live-validation run.
--
-- validation.validated_findings is an opaque JSON column holding the
-- ACTUAL OUTCOME of attempting each claimed finding against a running
-- system: confirmed, refuted, inconclusive, blocked by scope, or not
-- attempted and why. 208,346 of them across the live corpus, and none of
-- it was queryable.
--
-- Same relationship report_finding has to report.findings: the blob stays
-- authoritative and this is an index over it.
--
-- `source_finding_id` is the link back to the finding that was claimed, so
-- "was this ever proven against a live system" becomes a join rather than
-- a separate spreadsheet.
CREATE TABLE IF NOT EXISTS traust_storage.validation_finding (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    source_id TEXT NOT NULL,
    -- Parsed tail of source_id. The scan-scoped finding id, which is what
    -- report_finding is keyed on.
    source_finding_id TEXT,
    title TEXT,
    claimed_severity TEXT,
    surface TEXT,
    -- confirmed | refuted | inconclusive | blocked_by_scope | not_attempted.
    -- not_attempted DOMINATES in practice (184,148 of 208,346) and carries
    -- its reason separately: a validation lane that reported only attempts
    -- would describe 12% of its own work.
    verdict TEXT,
    skip_reason TEXT,
    technique TEXT,
    observed_impact TEXT,
    PRIMARY KEY (binding_id, source_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES traust_storage.artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_validation_finding_verdict
    ON traust_storage.validation_finding (verdict);

CREATE INDEX IF NOT EXISTS idx_validation_finding_source
    ON traust_storage.validation_finding (source_finding_id);
