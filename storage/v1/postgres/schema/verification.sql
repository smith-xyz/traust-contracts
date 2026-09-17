CREATE TABLE IF NOT EXISTS traust_storage.verification (
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
        REFERENCES traust_storage.artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_verification_artifact ON traust_storage.verification (artifact_digest);
