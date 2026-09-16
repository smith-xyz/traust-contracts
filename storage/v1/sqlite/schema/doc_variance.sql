CREATE TABLE IF NOT EXISTS doc_variance (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    metadata TEXT NOT NULL CHECK (metadata IS NULL OR json_valid(metadata)),
    records TEXT NOT NULL CHECK (records IS NULL OR json_valid(records)),
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_doc_variance_artifact ON doc_variance (artifact_digest);
