-- Projects layer metadata for scoped views without requiring traust-ledger.
CREATE TABLE IF NOT EXISTS layer_metadata (
    layer_id TEXT NOT NULL,
    project_id TEXT NOT NULL,
    repo TEXT,
    created_at TEXT,
    merkle_root TEXT,
    merkle_epoch BIGINT,
    artifact_digest TEXT NOT NULL,
    PRIMARY KEY (layer_id)
);

CREATE INDEX IF NOT EXISTS idx_layer_metadata_artifact
    ON layer_metadata (artifact_digest);

CREATE INDEX IF NOT EXISTS idx_layer_metadata_project
    ON layer_metadata (project_id);
