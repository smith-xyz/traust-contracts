CREATE TABLE IF NOT EXISTS traust_storage.benchmark_target (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    version BIGINT NOT NULL,
    updated TEXT NOT NULL,
    targets JSONB NOT NULL,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES traust_storage.artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_benchmark_target_artifact ON traust_storage.benchmark_target (artifact_digest);
