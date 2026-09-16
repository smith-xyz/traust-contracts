CREATE TABLE IF NOT EXISTS cloud_config_audit (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    title TEXT NOT NULL,
    metadata JSONB NOT NULL,
    summary JSONB NOT NULL,
    findings JSONB NOT NULL,
    gaps JSONB,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_cloud_config_audit_artifact ON cloud_config_audit (artifact_digest);
