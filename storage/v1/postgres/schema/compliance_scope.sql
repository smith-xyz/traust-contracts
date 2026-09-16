CREATE TABLE IF NOT EXISTS compliance_scope (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    version BIGINT NOT NULL,
    updated TEXT NOT NULL,
    boundaries JSONB NOT NULL,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_compliance_scope_artifact ON compliance_scope (artifact_digest);
