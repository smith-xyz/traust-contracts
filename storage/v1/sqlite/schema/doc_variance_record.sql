-- One row per doc-vs-code discrepancy: doc-variance.records[] fanned out
-- of the blob.
--
-- A record is an official documentation claim contradicted by code
-- evidence. The threat register rolled these up per product by walking
-- the tree, because doc_variance kept `records` as one JSON column and no
-- view could cut by variance class or disposition. `source` is flattened
-- into its declared members: the doc version is the join to a release
-- branch, and it was inside the block.
CREATE TABLE IF NOT EXISTS doc_variance_record (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    record_id TEXT NOT NULL,
    source_product_slug TEXT,
    source_version TEXT,
    source_guide TEXT,
    source_url TEXT,
    source_quote TEXT,
    claim TEXT,
    code_evidence TEXT CHECK (code_evidence IS NULL OR json_valid(code_evidence)),
    variance TEXT,
    verified_at TEXT,
    verified_against TEXT,
    disposition TEXT,
    disposition_note TEXT,
    finding_refs TEXT CHECK (finding_refs IS NULL OR json_valid(finding_refs)),
    threat_refs TEXT CHECK (threat_refs IS NULL OR json_valid(threat_refs)),
    PRIMARY KEY (binding_id, record_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_doc_variance_record_state
    ON doc_variance_record (disposition, variance);
