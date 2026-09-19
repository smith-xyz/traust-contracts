INSERT INTO traust_storage.layer_event (
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
    %(binding_id)s,
    %(artifact_digest)s,
    %(event_id)s,
    %(finding_ref)s,
    %(fingerprint)s,
    %(fingerprint_algo)s,
    %(recorded_at)s,
    %(occurred_at)s,
    %(source_type)s,
    %(source_ref)s,
    %(actor_kind)s,
    %(validity)s,
    %(resolution)s,
    %(evidence_grade)s,
    %(auto_accept_tier)s
)
ON CONFLICT (binding_id, event_id) DO NOTHING;
