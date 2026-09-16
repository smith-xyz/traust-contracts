INSERT INTO artifact_evidence (
    digest,
    payload,
    first_ingested_at
)
VALUES (
    :digest,
    :payload,
    :first_ingested_at
)
ON CONFLICT (digest) DO NOTHING;
