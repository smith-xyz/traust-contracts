CREATE TABLE IF NOT EXISTS benchmark_target (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    version INTEGER NOT NULL,
    updated TEXT NOT NULL,
    targets TEXT NOT NULL CHECK (targets IS NULL OR json_valid(targets))
);

CREATE INDEX IF NOT EXISTS idx_benchmark_target_project ON benchmark_target (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_benchmark_target_artifact ON benchmark_target (artifact_digest);
