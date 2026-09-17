INSERT INTO traust_storage.org_parameters (
    binding_id,
    artifact_digest,
    version,
    declared_by,
    declared_on,
    note,
    parameters
) VALUES (
    %(binding_id)s,
    %(artifact_digest)s,
    %(version)s,
    %(declared_by)s,
    %(declared_on)s,
    %(note)s,
    %(parameters)s
)
ON CONFLICT (binding_id) DO NOTHING;
