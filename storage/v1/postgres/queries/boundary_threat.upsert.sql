INSERT INTO traust_storage.boundary_threat (
    binding_id,
    artifact_digest,
    boundary_key,
    threat_id
)
VALUES (
    %(binding_id)s,
    %(artifact_digest)s,
    %(boundary_key)s,
    %(threat_id)s
)
ON CONFLICT (binding_id, boundary_key, threat_id) DO NOTHING;
