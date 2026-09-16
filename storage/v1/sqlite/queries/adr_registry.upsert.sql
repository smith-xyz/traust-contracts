INSERT INTO adr_registry (
    binding_id,
    artifact_digest,
    version,
    note,
    registers
) VALUES (
    :binding_id,
    :artifact_digest,
    :version,
    :note,
    :registers
)
ON CONFLICT (binding_id) DO NOTHING;
