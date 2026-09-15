CREATE TABLE IF NOT EXISTS artifact (
    digest TEXT NOT NULL,
    name TEXT NOT NULL,
    layer_id TEXT NOT NULL,
    project_id TEXT NOT NULL,
    payload BLOB NOT NULL,
    ingested_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (digest)
);

CREATE INDEX IF NOT EXISTS idx_artifact_layer
    ON artifact (layer_id);

CREATE INDEX IF NOT EXISTS idx_artifact_name
    ON artifact (name, project_id);
