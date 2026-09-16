CREATE TABLE IF NOT EXISTS adapter_result (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    target TEXT NOT NULL,
    scanned_at TEXT NOT NULL,
    metadata TEXT NOT NULL CHECK (metadata IS NULL OR json_valid(metadata)),
    findings TEXT NOT NULL CHECK (findings IS NULL OR json_valid(findings)),
    summary TEXT CHECK (summary IS NULL OR json_valid(summary)),
    focus_areas TEXT CHECK (focus_areas IS NULL OR json_valid(focus_areas)),
    PRIMARY KEY (binding_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_adapter_result_artifact ON adapter_result (artifact_digest);
