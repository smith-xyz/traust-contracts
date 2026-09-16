INSERT INTO compliance_scope (
    binding_id,
    artifact_digest,
    version,
    updated,
    boundaries
) VALUES (
    :binding_id,
    :artifact_digest,
    :version,
    :updated,
    :boundaries
)
ON CONFLICT (binding_id) DO NOTHING;
