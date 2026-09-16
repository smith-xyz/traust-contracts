CREATE TABLE IF NOT EXISTS pqc_readiness (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    title TEXT NOT NULL,
    metadata TEXT NOT NULL CHECK (metadata IS NULL OR json_valid(metadata)),
    scores TEXT NOT NULL CHECK (scores IS NULL OR json_valid(scores)),
    flags TEXT NOT NULL CHECK (flags IS NULL OR json_valid(flags)),
    provenance_summary TEXT NOT NULL CHECK (provenance_summary IS NULL OR json_valid(provenance_summary)),
    clock_items TEXT CHECK (clock_items IS NULL OR json_valid(clock_items)),
    readiness_bucket TEXT,
    fips_interaction TEXT CHECK (fips_interaction IS NULL OR json_valid(fips_interaction)),
    runtime_evidence TEXT CHECK (runtime_evidence IS NULL OR json_valid(runtime_evidence)),
    server_side_caveats TEXT CHECK (server_side_caveats IS NULL OR json_valid(server_side_caveats)),
    notes TEXT,
    remediations TEXT CHECK (remediations IS NULL OR json_valid(remediations)),
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_pqc_readiness_artifact ON pqc_readiness (artifact_digest);
