INSERT INTO isolation_review (
    binding_id,
    artifact_digest,
    title,
    metadata,
    interfaces,
    gaps,
    posture,
    notes
) VALUES (
    :binding_id,
    :artifact_digest,
    :title,
    :metadata,
    :interfaces,
    :gaps,
    :posture,
    :notes
)
ON CONFLICT (binding_id) DO NOTHING;
