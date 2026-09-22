-- Per-finding projection of a remediation verification.
--
-- verification.verified_findings[] is the answer to "did the fix hold", one
-- row per original finding re-audited. It lived in a JSON column, so the
-- regression count -- the single most consequential number this lane
-- produces -- could not be queried, only counted by a script walking files.
--
-- `verdict` is kept at five values, never folded to fixed/not-fixed.
-- partially_resolved and new_approach are real outcomes that a binary
-- reading reports as one of the two things they are not, and `regression`
-- is a verdict here as well as a separate array: the same re-audit can
-- resolve the original finding and introduce another.
--
-- `unattributed` marks a fix nobody could tie to a commit. It is evidence
-- about the evidence, and dropping it lets an unexplained pass read exactly
-- like a demonstrated one.
CREATE TABLE IF NOT EXISTS traust_storage.verification_finding (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    original_id TEXT NOT NULL,
    original_title TEXT,
    original_severity TEXT,
    verdict TEXT,
    remediation_commits JSONB,
    unattributed INTEGER,
    -- The evidence block flattened into its four declared members.
    -- Kept apart rather than stored whole because a nested evidence
    -- block is exactly where fields go missing unnoticed: 15 of
    -- impact-analysis's 19 did, inside one opaque column.
    evidence_explanation TEXT,
    evidence_framework_reference TEXT,
    evidence_original_code TEXT,
    evidence_patched_code TEXT,
    disposition_rationale TEXT,
    residual_risk TEXT,
    residual_severity TEXT,
    cross_repo JSONB,
    PRIMARY KEY (binding_id, original_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES traust_storage.artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_verification_finding_verdict
    ON traust_storage.verification_finding (verdict);

CREATE INDEX IF NOT EXISTS idx_verification_finding_unattributed
    ON traust_storage.verification_finding (unattributed);
