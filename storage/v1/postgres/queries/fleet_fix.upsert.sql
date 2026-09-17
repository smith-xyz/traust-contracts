INSERT INTO traust_storage.fleet_fix (
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
    %(binding_id)s,
    %(artifact_digest)s,
    %(id)s,
    %(pattern_ref)s,
    %(description)s,
    %(matcher)s,
    %(resolver)s,
    %(rewrite)s,
    %(guards)s,
    %(tests)s
)
ON CONFLICT (binding_id) DO NOTHING;
