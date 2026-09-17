CREATE TABLE IF NOT EXISTS traust_storage.compliance_mapping (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    version BIGINT NOT NULL,
    note TEXT,
    controls JSONB NOT NULL,
    checks JSONB NOT NULL,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES traust_storage.artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_compliance_mapping_artifact ON traust_storage.compliance_mapping (artifact_digest);
