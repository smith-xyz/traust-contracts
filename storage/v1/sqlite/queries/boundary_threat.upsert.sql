INSERT INTO boundary_threat (
    binding_id,
    artifact_digest,
    boundary_key,
    threat_id
)
VALUES (
    :binding_id,
    :artifact_digest,
    :boundary_key,
    :threat_id
)
ON CONFLICT (binding_id, boundary_key, threat_id) DO NOTHING;
