-- Ownership for each audited subject: the denominator every dashboard cut
-- divides by.
--
-- Nothing in the contract modelled this. Ownership lived only in the
-- deployment's corpus-config and in the harness's own SQLite projection, so
-- "X% of our repos" could not be computed from storage/v1 at all. Projected
-- from the corpus-registry artifact, keyed on the same subject_id that
-- artifact_binding carries, so findings join to ownership in SQL.
CREATE TABLE IF NOT EXISTS subject_ownership (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    subject_id TEXT NOT NULL,
    tree TEXT NOT NULL,
    ownership TEXT NOT NULL,
    business_unit TEXT NOT NULL,
    label TEXT,
    product TEXT,
    repo_url TEXT,
    ref TEXT,
    ref_kind TEXT,
    -- Load-bearing: a large share of audits are branch re-audits of the same
    -- code, so a denominator that does not exclude them overstates coverage.
    is_branch_audit INTEGER,
    PRIMARY KEY (binding_id, subject_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_subject_ownership_subject
    ON subject_ownership (subject_id);

CREATE INDEX IF NOT EXISTS idx_subject_ownership_cut
    ON subject_ownership (ownership, business_unit);
