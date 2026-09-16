INSERT INTO verification (
    binding_id,
    artifact_digest,
    title,
    metadata,
    summary,
    verified_findings,
    regressions,
    commit_timeline,
    evidence,
    recommendations,
    notes,
    footer
) VALUES (
    :binding_id,
    :artifact_digest,
    :title,
    :metadata,
    :summary,
    :verified_findings,
    :regressions,
    :commit_timeline,
    :evidence,
    :recommendations,
    :notes,
    :footer
)
ON CONFLICT (binding_id) DO NOTHING;
