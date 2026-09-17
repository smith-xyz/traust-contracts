INSERT INTO traust_storage.adapter_result (
    binding_id,
    artifact_digest,
    target,
    scanned_at,
    metadata,
    findings,
    summary,
    focus_areas
) VALUES (
    %(binding_id)s,
    %(artifact_digest)s,
    %(target)s,
    %(scanned_at)s,
    %(metadata)s,
    %(findings)s,
    %(summary)s,
    %(focus_areas)s
)
ON CONFLICT (binding_id) DO NOTHING;
