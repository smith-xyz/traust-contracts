CREATE TABLE IF NOT EXISTS remediation (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    title TEXT NOT NULL,
    metadata TEXT NOT NULL CHECK (metadata IS NULL OR json_valid(metadata)),
    source_findings TEXT NOT NULL CHECK (source_findings IS NULL OR json_valid(source_findings)),
    fork TEXT NOT NULL CHECK (fork IS NULL OR json_valid(fork)),
    patch TEXT NOT NULL CHECK (patch IS NULL OR json_valid(patch)),
    checks TEXT NOT NULL CHECK (checks IS NULL OR json_valid(checks)),
    evidence TEXT CHECK (evidence IS NULL OR json_valid(evidence)),
    revalidation TEXT CHECK (revalidation IS NULL OR json_valid(revalidation)),
    pull_request TEXT CHECK (pull_request IS NULL OR json_valid(pull_request)),
    summary TEXT NOT NULL CHECK (summary IS NULL OR json_valid(summary)),
    notes TEXT,
    footer TEXT,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_remediation_artifact ON remediation (artifact_digest);
