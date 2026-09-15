CREATE TABLE IF NOT EXISTS pqc_readiness (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    title TEXT NOT NULL,
    metadata JSONB NOT NULL,
    scores JSONB NOT NULL,
    flags JSONB NOT NULL,
    provenance_summary JSONB NOT NULL,
    clock_items JSONB,
    readiness_bucket TEXT,
    fips_interaction JSONB,
    runtime_evidence JSONB,
    server_side_caveats JSONB,
    notes TEXT,
    remediations JSONB
);

CREATE INDEX IF NOT EXISTS idx_pqc_readiness_project ON pqc_readiness (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_pqc_readiness_artifact ON pqc_readiness (artifact_digest);
