INSERT INTO benchmark_target (
    binding_id,
    artifact_digest,
    version,
    updated,
    targets
) VALUES (
    :binding_id,
    :artifact_digest,
    :version,
    :updated,
    :targets
)
ON CONFLICT (binding_id) DO NOTHING;
