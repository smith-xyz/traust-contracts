CREATE TABLE IF NOT EXISTS compliance_mapping (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    version INTEGER NOT NULL,
    note TEXT,
    controls TEXT NOT NULL CHECK (controls IS NULL OR json_valid(controls)),
    checks TEXT NOT NULL CHECK (checks IS NULL OR json_valid(checks)),
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_compliance_mapping_artifact ON compliance_mapping (artifact_digest);
