INSERT INTO layer_metadata (
    binding_id,
    artifact_digest,
    repo,
    created_at,
    merkle_root,
    merkle_epoch
)
VALUES (
    :binding_id,
    :artifact_digest,
    :repo,
    :created_at,
    :merkle_root,
    :merkle_epoch
)
ON CONFLICT (binding_id) DO NOTHING;
