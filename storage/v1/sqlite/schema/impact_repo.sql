-- One row per repository an advisory reaches: impact-analysis.repos[]
-- fanned out of the blob.
--
-- advisory_exposure used to JOIN json_each(impact_analysis.repos) at query
-- time, which storage/v1/README.md rule 3 forbids: per-item fields are
-- projected as COLUMNS, never joined out of the blob when read. The view
-- now selects from here and its output columns are unchanged.
--
-- `evidence` is flattened into its declared members rather than stored
-- whole -- a nested block is exactly where fields go missing unnoticed,
-- and these are how the classification was reached. Null in an evidence
-- column means NOT ESTABLISHED, never "no". `direct` separates a
-- first-order dependency from a transitive one.
CREATE TABLE IF NOT EXISTS impact_repo (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    repo TEXT NOT NULL,
    classification TEXT NOT NULL,
    version TEXT,
    direct INTEGER,
    products TEXT CHECK (products IS NULL OR json_valid(products)),
    -- The contract's own tier and the column to rank on:
    -- symbol > binary > manifest.
    evidence_level TEXT,
    l1_depends_on INTEGER,
    l1_version_in_range INTEGER,
    l4_package_imported INTEGER,
    l4_packages_found TEXT CHECK (l4_packages_found IS NULL OR json_valid(l4_packages_found)),
    govulncheck TEXT,
    govulncheck_trace TEXT CHECK (govulncheck_trace IS NULL OR json_valid(govulncheck_trace)),
    feature_pattern_matches INTEGER,
    binary_string_scan TEXT,
    binary_symbol_scan TEXT,
    binary_linked_library TEXT,
    symbol_usage_scan TEXT,
    source_import_scan TEXT,
    manifest_scan TEXT,
    manifest_version TEXT,
    sbom_scan TEXT,
    sbom_shipped_version TEXT,
    needs_manual_trace INTEGER,
    notes TEXT,
    PRIMARY KEY (binding_id, repo),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_impact_repo_classification
    ON impact_repo (classification);

CREATE INDEX IF NOT EXISTS idx_impact_repo_repo
    ON impact_repo (repo);
