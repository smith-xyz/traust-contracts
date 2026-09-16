INSERT INTO compliance_mapping (
    binding_id,
    artifact_digest,
    version,
    note,
    controls,
    checks
) VALUES (
    %(binding_id)s,
    %(artifact_digest)s,
    %(version)s,
    %(note)s,
    %(controls)s,
    %(checks)s
)
ON CONFLICT (binding_id) DO NOTHING;
