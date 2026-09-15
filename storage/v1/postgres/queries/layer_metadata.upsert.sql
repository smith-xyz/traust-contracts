INSERT INTO layer_metadata (
    layer_id,
    project_id,
    repo,
    created_at,
    merkle_root,
    merkle_epoch,
    artifact_digest
)
VALUES (
    %(layer_id)s,
    %(project_id)s,
    %(repo)s,
    %(created_at)s,
    %(merkle_root)s,
    %(merkle_epoch)s,
    %(artifact_digest)s
)
ON CONFLICT (layer_id) DO UPDATE SET
    project_id = EXCLUDED.project_id,
    repo = EXCLUDED.repo,
    created_at = EXCLUDED.created_at,
    merkle_root = EXCLUDED.merkle_root,
    merkle_epoch = EXCLUDED.merkle_epoch,
    artifact_digest = EXCLUDED.artifact_digest;
