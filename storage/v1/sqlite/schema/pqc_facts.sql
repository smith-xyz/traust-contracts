CREATE TABLE IF NOT EXISTS pqc_facts (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    artifact TEXT NOT NULL,
    repository TEXT NOT NULL,
    stamps TEXT NOT NULL CHECK (stamps IS NULL OR json_valid(stamps)),
    coverage TEXT NOT NULL CHECK (coverage IS NULL OR json_valid(coverage)),
    summary TEXT NOT NULL CHECK (summary IS NULL OR json_valid(summary)),
    facts TEXT NOT NULL CHECK (facts IS NULL OR json_valid(facts))
);

CREATE INDEX IF NOT EXISTS idx_pqc_facts_project ON pqc_facts (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_pqc_facts_artifact ON pqc_facts (artifact_digest);
