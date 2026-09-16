CREATE TABLE IF NOT EXISTS adapter_result (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    target TEXT NOT NULL,
    scanned_at TEXT NOT NULL,
    metadata JSONB NOT NULL,
    findings JSONB NOT NULL,
    summary JSONB,
    focus_areas JSONB,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_adapter_result_artifact ON adapter_result (artifact_digest);
