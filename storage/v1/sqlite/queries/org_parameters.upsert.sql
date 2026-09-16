INSERT INTO org_parameters (
    binding_id,
    artifact_digest,
    version,
    declared_by,
    declared_on,
    note,
    parameters
) VALUES (
    :binding_id,
    :artifact_digest,
    :version,
    :declared_by,
    :declared_on,
    :note,
    :parameters
)
ON CONFLICT (binding_id) DO NOTHING;
