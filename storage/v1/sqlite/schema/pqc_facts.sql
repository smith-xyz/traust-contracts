CREATE TABLE IF NOT EXISTS pqc_facts (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    artifact TEXT NOT NULL,
    repository TEXT NOT NULL,
    stamps TEXT NOT NULL CHECK (stamps IS NULL OR json_valid(stamps)),
    coverage TEXT NOT NULL CHECK (coverage IS NULL OR json_valid(coverage)),
    summary TEXT NOT NULL CHECK (summary IS NULL OR json_valid(summary)),
    facts TEXT NOT NULL CHECK (facts IS NULL OR json_valid(facts)),
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_pqc_facts_artifact ON pqc_facts (artifact_digest);
