CREATE TABLE IF NOT EXISTS remediation (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    title TEXT NOT NULL,
    metadata TEXT NOT NULL CHECK (metadata IS NULL OR json_valid(metadata)),
    source_findings TEXT NOT NULL CHECK (source_findings IS NULL OR json_valid(source_findings)),
    fork TEXT NOT NULL CHECK (fork IS NULL OR json_valid(fork)),
    patch TEXT NOT NULL CHECK (patch IS NULL OR json_valid(patch)),
    checks TEXT NOT NULL CHECK (checks IS NULL OR json_valid(checks)),
    revalidation TEXT CHECK (revalidation IS NULL OR json_valid(revalidation)),
    pull_request TEXT CHECK (pull_request IS NULL OR json_valid(pull_request)),
    summary TEXT NOT NULL CHECK (summary IS NULL OR json_valid(summary)),
    notes TEXT,
    footer TEXT
);

CREATE INDEX IF NOT EXISTS idx_remediation_project ON remediation (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_remediation_artifact ON remediation (artifact_digest);
