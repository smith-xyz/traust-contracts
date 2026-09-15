CREATE TABLE IF NOT EXISTS risk_rating_methodology (
    layer_id TEXT PRIMARY KEY,
    project_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    methodology TEXT NOT NULL,
    methodology_version TEXT NOT NULL,
    source TEXT NOT NULL,
    documentation TEXT,
    schema TEXT,
    bands TEXT NOT NULL CHECK (bands IS NULL OR json_valid(bands)),
    bucket_thresholds TEXT NOT NULL CHECK (bucket_thresholds IS NULL OR json_valid(bucket_thresholds)),
    likelihood_factors TEXT NOT NULL CHECK (likelihood_factors IS NULL OR json_valid(likelihood_factors)),
    impact_factors TEXT NOT NULL CHECK (impact_factors IS NULL OR json_valid(impact_factors)),
    matrix TEXT NOT NULL CHECK (matrix IS NULL OR json_valid(matrix)),
    fallback TEXT NOT NULL CHECK (fallback IS NULL OR json_valid(fallback)),
    threat_intel_factor TEXT CHECK (threat_intel_factor IS NULL OR json_valid(threat_intel_factor))
);

CREATE INDEX IF NOT EXISTS idx_risk_rating_methodology_project ON risk_rating_methodology (project_id, layer_id);
CREATE INDEX IF NOT EXISTS idx_risk_rating_methodology_artifact ON risk_rating_methodology (artifact_digest);
