INSERT INTO adapter_result (
    binding_id,
    artifact_digest,
    target,
    scanned_at,
    metadata,
    findings,
    summary,
    focus_areas
) VALUES (
    :binding_id,
    :artifact_digest,
    :target,
    :scanned_at,
    :metadata,
    :findings,
    :summary,
    :focus_areas
)
ON CONFLICT (binding_id) DO NOTHING;
