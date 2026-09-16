CREATE TABLE IF NOT EXISTS doc_variance (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    metadata JSONB NOT NULL,
    records JSONB NOT NULL,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_doc_variance_artifact ON doc_variance (artifact_digest);
