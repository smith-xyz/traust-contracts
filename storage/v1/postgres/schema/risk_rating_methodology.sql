CREATE TABLE IF NOT EXISTS risk_rating_methodology (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    methodology TEXT NOT NULL,
    methodology_version TEXT NOT NULL,
    source TEXT NOT NULL,
    documentation TEXT,
    schema TEXT,
    bands JSONB NOT NULL,
    bucket_thresholds JSONB NOT NULL,
    likelihood_factors JSONB NOT NULL,
    impact_factors JSONB NOT NULL,
    matrix JSONB NOT NULL,
    fallback JSONB NOT NULL,
    threat_intel_factor JSONB
);

CREATE INDEX IF NOT EXISTS idx_risk_rating_methodology_project ON risk_rating_methodology (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_risk_rating_methodology_artifact ON risk_rating_methodology (artifact_digest);
