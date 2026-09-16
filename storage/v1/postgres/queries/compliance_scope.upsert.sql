INSERT INTO compliance_scope (
    binding_id,
    artifact_digest,
    version,
    updated,
    boundaries
) VALUES (
    %(binding_id)s,
    %(artifact_digest)s,
    %(version)s,
    %(updated)s,
    %(boundaries)s
)
ON CONFLICT (binding_id) DO NOTHING;
