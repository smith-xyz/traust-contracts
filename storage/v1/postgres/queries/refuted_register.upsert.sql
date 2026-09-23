INSERT INTO traust_storage.refuted_register (
    binding_id, artifact_digest, source, sources, generated_at, entries
) VALUES (
    %(binding_id)s, %(artifact_digest)s, %(source)s, %(sources)s, %(generated_at)s, %(entries)s
)
ON CONFLICT (binding_id) DO NOTHING;
