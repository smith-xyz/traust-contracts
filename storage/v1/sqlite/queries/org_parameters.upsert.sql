INSERT INTO org_parameters (
    layer_id,
    project_id,
    artifact_digest,
    version,
    declared_by,
    declared_on,
    note,
    parameters
) VALUES (
    :layer_id,
    :project_id,
    :artifact_digest,
    :version,
    :declared_by,
    :declared_on,
    :note,
    :parameters
)
ON CONFLICT (layer_id) DO UPDATE SET
    project_id = excluded.project_id,
    artifact_digest = excluded.artifact_digest,
    version = excluded.version,
    declared_by = excluded.declared_by,
    declared_on = excluded.declared_on,
    note = excluded.note,
    parameters = excluded.parameters;
