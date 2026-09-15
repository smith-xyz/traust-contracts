INSERT INTO adapter_result (
    layer_id,
    project_id,
    artifact_digest,
    target,
    scanned_at,
    metadata,
    findings,
    summary,
    focus_areas
) VALUES (
    %(layer_id)s,
    %(project_id)s,
    %(artifact_digest)s,
    %(target)s,
    %(scanned_at)s,
    %(metadata)s,
    %(findings)s,
    %(summary)s,
    %(focus_areas)s
)
ON CONFLICT (layer_id) DO UPDATE SET
    project_id = excluded.project_id,
    artifact_digest = excluded.artifact_digest,
    target = excluded.target,
    scanned_at = excluded.scanned_at,
    metadata = excluded.metadata,
    findings = excluded.findings,
    summary = excluded.summary,
    focus_areas = excluded.focus_areas;
