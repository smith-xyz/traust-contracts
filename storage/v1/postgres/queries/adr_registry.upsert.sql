INSERT INTO adr_registry (
    layer_id,
    project_id,
    artifact_digest,
    version,
    note,
    registers
) VALUES (
    %(layer_id)s,
    %(project_id)s,
    %(artifact_digest)s,
    %(version)s,
    %(note)s,
    %(registers)s
)
ON CONFLICT (layer_id) DO UPDATE SET
    project_id = excluded.project_id,
    artifact_digest = excluded.artifact_digest,
    version = excluded.version,
    note = excluded.note,
    registers = excluded.registers;
