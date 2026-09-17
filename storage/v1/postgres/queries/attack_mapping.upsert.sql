INSERT INTO traust_storage.attack_mapping (
    binding_id,
    artifact_digest,
    mapping_version,
    attack_version,
    source,
    documentation,
    schema,
    attribution,
    capability_map,
    category_map
) VALUES (
    %(binding_id)s,
    %(artifact_digest)s,
    %(mapping_version)s,
    %(attack_version)s,
    %(source)s,
    %(documentation)s,
    %(schema)s,
    %(attribution)s,
    %(capability_map)s,
    %(category_map)s
)
ON CONFLICT (binding_id) DO NOTHING;
