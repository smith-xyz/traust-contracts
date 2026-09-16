CREATE TABLE IF NOT EXISTS risk_rating_methodology (
    binding_id TEXT NOT NULL,
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
    threat_intel_factor JSONB,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_risk_rating_methodology_artifact ON risk_rating_methodology (artifact_digest);
