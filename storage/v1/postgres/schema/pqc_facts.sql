CREATE TABLE IF NOT EXISTS pqc_facts (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    artifact TEXT NOT NULL,
    repository TEXT NOT NULL,
    stamps JSONB NOT NULL,
    coverage JSONB NOT NULL,
    summary JSONB NOT NULL,
    facts JSONB NOT NULL,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_pqc_facts_artifact ON pqc_facts (artifact_digest);
