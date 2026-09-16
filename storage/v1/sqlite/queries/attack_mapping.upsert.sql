INSERT INTO attack_mapping (
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
    :binding_id,
    :artifact_digest,
    :mapping_version,
    :attack_version,
    :source,
    :documentation,
    :schema,
    :attribution,
    :capability_map,
    :category_map
)
ON CONFLICT (binding_id) DO NOTHING;
