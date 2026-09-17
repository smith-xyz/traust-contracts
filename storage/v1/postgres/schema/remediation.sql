CREATE TABLE IF NOT EXISTS traust_storage.remediation (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    title TEXT NOT NULL,
    metadata JSONB NOT NULL,
    source_findings JSONB NOT NULL,
    fork JSONB NOT NULL,
    patch JSONB NOT NULL,
    checks JSONB NOT NULL,
    evidence JSONB,
    revalidation JSONB,
    pull_request JSONB,
    summary JSONB NOT NULL,
    notes TEXT,
    footer TEXT,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES traust_storage.artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_remediation_artifact ON traust_storage.remediation (artifact_digest);
