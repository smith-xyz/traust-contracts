CREATE TABLE IF NOT EXISTS pqc_facts (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    artifact TEXT NOT NULL,
    repository TEXT NOT NULL,
    stamps JSONB NOT NULL,
    coverage JSONB NOT NULL,
    summary JSONB NOT NULL,
    facts JSONB NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_pqc_facts_project ON pqc_facts (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_pqc_facts_artifact ON pqc_facts (artifact_digest);
