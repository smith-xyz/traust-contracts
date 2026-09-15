INSERT INTO fleet_fix (
    layer_id,
    project_id,
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
    :layer_id,
    :project_id,
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
ON CONFLICT (layer_id) DO UPDATE SET
    project_id = excluded.project_id,
    artifact_digest = excluded.artifact_digest,
    id = excluded.id,
    pattern_ref = excluded.pattern_ref,
    description = excluded.description,
    matcher = excluded.matcher,
    resolver = excluded.resolver,
    rewrite = excluded.rewrite,
    guards = excluded.guards,
    tests = excluded.tests;
