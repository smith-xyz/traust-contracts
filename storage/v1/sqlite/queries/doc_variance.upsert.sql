INSERT INTO doc_variance (
    binding_id,
    artifact_digest,
    metadata,
    records
) VALUES (
    :binding_id,
    :artifact_digest,
    :metadata,
    :records
)
ON CONFLICT (binding_id) DO NOTHING;
