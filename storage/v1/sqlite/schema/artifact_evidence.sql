CREATE TABLE IF NOT EXISTS artifact_evidence (
    digest TEXT NOT NULL,
    payload BLOB NOT NULL,
    first_ingested_at TEXT NOT NULL,
    PRIMARY KEY (digest)
);
