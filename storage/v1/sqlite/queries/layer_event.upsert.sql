INSERT INTO layer_event (
    binding_id,
    artifact_digest,
    event_id,
    finding_ref,
    fingerprint,
    fingerprint_algo,
    recorded_at,
    occurred_at,
    source_type,
    source_ref,
    actor_kind,
    validity,
    resolution,
    evidence_grade,
    auto_accept_tier
)
VALUES (
    :binding_id,
    :artifact_digest,
    :event_id,
    :finding_ref,
    :fingerprint,
    :fingerprint_algo,
    :recorded_at,
    :occurred_at,
    :source_type,
    :source_ref,
    :actor_kind,
    :validity,
    :resolution,
    :evidence_grade,
    :auto_accept_tier
)
ON CONFLICT (binding_id, event_id) DO NOTHING;
