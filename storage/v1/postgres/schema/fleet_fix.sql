CREATE TABLE IF NOT EXISTS fleet_fix (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    id TEXT NOT NULL,
    pattern_ref TEXT NOT NULL,
    description TEXT NOT NULL,
    matcher JSONB NOT NULL,
    resolver JSONB,
    rewrite JSONB NOT NULL,
    guards JSONB NOT NULL,
    tests JSONB NOT NULL,
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_fleet_fix_artifact ON fleet_fix (artifact_digest);
