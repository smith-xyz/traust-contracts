INSERT INTO traust_storage.layer_metadata (
    binding_id,
    artifact_digest,
    repo,
    created_at,
    merkle_root,
    merkle_epoch
)
VALUES (
    %(binding_id)s,
    %(artifact_digest)s,
    %(repo)s,
    %(created_at)s,
    %(merkle_root)s,
    %(merkle_epoch)s
)
ON CONFLICT (binding_id) DO NOTHING;
