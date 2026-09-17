INSERT INTO traust_storage.adr_registry (
    binding_id,
    artifact_digest,
    version,
    note,
    registers
) VALUES (
    %(binding_id)s,
    %(artifact_digest)s,
    %(version)s,
    %(note)s,
    %(registers)s
)
ON CONFLICT (binding_id) DO NOTHING;
