INSERT INTO refuted_register (
    binding_id, artifact_digest, source, sources, generated_at, entries
) VALUES (
    :binding_id, :artifact_digest, :source, :sources, :generated_at, :entries
)
ON CONFLICT (binding_id) DO NOTHING;
