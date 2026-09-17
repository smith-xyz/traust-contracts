INSERT INTO traust_storage.doc_variance (
    binding_id,
    artifact_digest,
    metadata,
    records
) VALUES (
    %(binding_id)s,
    %(artifact_digest)s,
    %(metadata)s,
    %(records)s
)
ON CONFLICT (binding_id) DO NOTHING;
