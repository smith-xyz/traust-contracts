INSERT INTO attack_mapping (
    layer_id,
    project_id,
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
    :layer_id,
    :project_id,
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
ON CONFLICT (layer_id) DO UPDATE SET
    project_id = excluded.project_id,
    artifact_digest = excluded.artifact_digest,
    mapping_version = excluded.mapping_version,
    attack_version = excluded.attack_version,
    source = excluded.source,
    documentation = excluded.documentation,
    schema = excluded.schema,
    attribution = excluded.attribution,
    capability_map = excluded.capability_map,
    category_map = excluded.category_map;
