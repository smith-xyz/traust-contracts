-- One row per tenant boundary a threat model declares:
-- threat-model.tenant_boundaries[] fanned out of the blob.
--
-- The threat register rolls these up fleet-wide -- which boundaries are
-- weakest, and which open threats sit behind each -- and had to parse
-- them out of prose because nothing projected them: the coverage gate
-- checked the threats[] item and never asked about the artifact's other
-- root arrays. boundary_key is `<subject>:<boundary_id>` for the same
-- reason threat_key is: an in-model id repeats across every model.
--
-- The five isolation dimensions are the model's own stated results and
-- are carried verbatim; the register's weakness ordering is derived in
-- boundary_current from them, never stored.
CREATE TABLE IF NOT EXISTS threat_boundary (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    boundary_key TEXT NOT NULL,
    boundary_id TEXT NOT NULL,
    subject_id TEXT,
    product TEXT,
    interface TEXT,
    kind TEXT,
    exposure TEXT,
    complexity TEXT,
    privilege TEXT,
    encryption TEXT,
    authentication TEXT,
    connectivity TEXT,
    hygiene TEXT,
    -- Kept whole for the record; the per-id rows live in boundary_threat
    -- so a view joins rather than matching against the array.
    threat_ids TEXT CHECK (threat_ids IS NULL OR json_valid(threat_ids)),
    isolation_review_ref TEXT,
    PRIMARY KEY (binding_id, boundary_key),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_threat_boundary_subject
    ON threat_boundary (subject_id);

CREATE INDEX IF NOT EXISTS idx_threat_boundary_exposure
    ON threat_boundary (exposure, kind);
