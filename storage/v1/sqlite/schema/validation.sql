CREATE TABLE IF NOT EXISTS validation (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    title TEXT NOT NULL,
    metadata TEXT NOT NULL CHECK (metadata IS NULL OR json_valid(metadata)),
    source_reports TEXT NOT NULL CHECK (source_reports IS NULL OR json_valid(source_reports)),
    summary TEXT NOT NULL CHECK (summary IS NULL OR json_valid(summary)),
    validated_findings TEXT NOT NULL CHECK (validated_findings IS NULL OR json_valid(validated_findings)),
    attack_chains TEXT NOT NULL CHECK (attack_chains IS NULL OR json_valid(attack_chains)),
    novel_findings TEXT NOT NULL CHECK (novel_findings IS NULL OR json_valid(novel_findings)),
    negative_results TEXT CHECK (negative_results IS NULL OR json_valid(negative_results)),
    execution_log_ref TEXT NOT NULL,
    execution_log_sha256 TEXT,
    footer TEXT
);

CREATE INDEX IF NOT EXISTS idx_validation_project ON validation (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_validation_artifact ON validation (artifact_digest);
