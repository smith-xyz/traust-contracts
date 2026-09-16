CREATE TABLE IF NOT EXISTS artifact_evidence (
    digest TEXT NOT NULL,
    payload BYTEA NOT NULL,
    first_ingested_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (digest)
);
