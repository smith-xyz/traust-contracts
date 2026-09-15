INSERT INTO adr_registry (
    layer_id,
    project_id,
    artifact_digest,
    version,
    note,
    registers
) VALUES (
    :layer_id,
    :project_id,
    :artifact_digest,
    :version,
    :note,
    :registers
)
ON CONFLICT (layer_id) DO UPDATE SET
    project_id = excluded.project_id,
    artifact_digest = excluded.artifact_digest,
    version = excluded.version,
    note = excluded.note,
    registers = excluded.registers;
