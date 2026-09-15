INSERT INTO artifact (
    digest,
    name,
    layer_id,
    project_id,
    payload,
    ingested_at
)
VALUES (
    %(digest)s,
    %(name)s,
    %(layer_id)s,
    %(project_id)s,
    %(payload)s,
    %(ingested_at)s
)
ON CONFLICT (digest) DO UPDATE SET
    name = EXCLUDED.name,
    layer_id = EXCLUDED.layer_id,
    project_id = EXCLUDED.project_id,
    payload = EXCLUDED.payload,
    ingested_at = EXCLUDED.ingested_at;
