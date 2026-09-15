CREATE TABLE IF NOT EXISTS verification (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    title TEXT NOT NULL,
    metadata TEXT NOT NULL CHECK (metadata IS NULL OR json_valid(metadata)),
    summary TEXT NOT NULL CHECK (summary IS NULL OR json_valid(summary)),
    verified_findings TEXT NOT NULL CHECK (verified_findings IS NULL OR json_valid(verified_findings)),
    regressions TEXT NOT NULL CHECK (regressions IS NULL OR json_valid(regressions)),
    commit_timeline TEXT NOT NULL CHECK (commit_timeline IS NULL OR json_valid(commit_timeline)),
    recommendations TEXT CHECK (recommendations IS NULL OR json_valid(recommendations)),
    notes TEXT,
    footer TEXT
);

CREATE INDEX IF NOT EXISTS idx_verification_project ON verification (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_verification_artifact ON verification (artifact_digest);
