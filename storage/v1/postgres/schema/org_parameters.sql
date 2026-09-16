CREATE TABLE IF NOT EXISTS org_parameters (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    version BIGINT NOT NULL,
    declared_by TEXT NOT NULL,
    declared_on TEXT,
    note TEXT,
    parameters JSONB NOT NULL,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_org_parameters_artifact ON org_parameters (artifact_digest);
