INSERT INTO compliance_mapping (
    binding_id,
    artifact_digest,
    version,
    note,
    controls,
    checks
) VALUES (
    :binding_id,
    :artifact_digest,
    :version,
    :note,
    :controls,
    :checks
)
ON CONFLICT (binding_id) DO NOTHING;
