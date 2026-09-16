CREATE TABLE IF NOT EXISTS verification (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    title TEXT NOT NULL,
    metadata TEXT NOT NULL CHECK (metadata IS NULL OR json_valid(metadata)),
    summary TEXT NOT NULL CHECK (summary IS NULL OR json_valid(summary)),
    verified_findings TEXT NOT NULL CHECK (verified_findings IS NULL OR json_valid(verified_findings)),
    regressions TEXT NOT NULL CHECK (regressions IS NULL OR json_valid(regressions)),
    commit_timeline TEXT NOT NULL CHECK (commit_timeline IS NULL OR json_valid(commit_timeline)),
    recommendations TEXT CHECK (recommendations IS NULL OR json_valid(recommendations)),
    notes TEXT,
    footer TEXT,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_verification_artifact ON verification (artifact_digest);
