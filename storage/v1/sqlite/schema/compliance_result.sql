-- Per-control projection of a compliance assessment.
--
-- compliance-assessment.results[] is the assessment: one row per control per
-- framework, each with a verdict and -- the part that matters -- WHERE the
-- verdict came from. The family projected one row per artifact with results
-- in a JSON column, so "which controls are not satisfied" could not be asked
-- of SQL at all, and no compliance dashboard could be expressed as a view.
--
-- verdict_source is carried, never collapsed into verdict. A control
-- satisfied by a deterministic check, one satisfied by an agent reading
-- evidence, and one satisfied by a human override are three different
-- claims about assurance, and a posture that reports only "satisfied"
-- erases the distinction an auditor is there to examine.
--
-- The override block travels with the row for the same reason: an override
-- records who set it aside and why, which is precisely what a reviewer
-- needs and what a bare verdict hides.
CREATE TABLE IF NOT EXISTS compliance_result (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    framework TEXT NOT NULL,
    control_id TEXT NOT NULL,
    title TEXT,
    classification TEXT,
    verdict TEXT,
    verdict_source TEXT,
    check_id TEXT,
    reason TEXT,
    narrative TEXT,
    evidence TEXT CHECK (evidence IS NULL OR json_valid(evidence)),
    override TEXT CHECK (override IS NULL OR json_valid(override)),
    n_pass_agreement TEXT CHECK (n_pass_agreement IS NULL OR json_valid(n_pass_agreement)),
    PRIMARY KEY (binding_id, framework, control_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_compliance_result_verdict
    ON compliance_result (framework, verdict);

CREATE INDEX IF NOT EXISTS idx_compliance_result_control
    ON compliance_result (control_id);
