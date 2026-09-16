CREATE TABLE IF NOT EXISTS verification (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    title TEXT NOT NULL,
    metadata JSONB NOT NULL,
    summary JSONB NOT NULL,
    verified_findings JSONB NOT NULL,
    regressions JSONB NOT NULL,
    commit_timeline JSONB NOT NULL,
    evidence JSONB,
    recommendations JSONB,
    notes TEXT,
    footer TEXT,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_verification_artifact ON verification (artifact_digest);
