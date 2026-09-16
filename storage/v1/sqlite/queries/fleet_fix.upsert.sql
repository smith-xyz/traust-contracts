INSERT INTO fleet_fix (
    binding_id,
    artifact_digest,
    id,
    pattern_ref,
    description,
    matcher,
    resolver,
    rewrite,
    guards,
    tests
) VALUES (
    :binding_id,
    :artifact_digest,
    :id,
    :pattern_ref,
    :description,
    :matcher,
    :resolver,
    :rewrite,
    :guards,
    :tests
)
ON CONFLICT (binding_id) DO NOTHING;
