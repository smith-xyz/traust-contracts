INSERT INTO traust_storage.artifact_evidence (
    digest,
    payload,
    first_ingested_at
)
VALUES (
    %(digest)s,
    %(payload)s,
    %(first_ingested_at)s
)
ON CONFLICT (digest) DO NOTHING;
