INSERT INTO verification (
    layer_id,
    project_id,
    artifact_digest,
    title,
    metadata,
    summary,
    verified_findings,
    regressions,
    commit_timeline,
    recommendations,
    notes,
    footer
) VALUES (
    :layer_id,
    :project_id,
    :artifact_digest,
    :title,
    :metadata,
    :summary,
    :verified_findings,
    :regressions,
    :commit_timeline,
    :recommendations,
    :notes,
    :footer
)
ON CONFLICT (layer_id) DO UPDATE SET
    project_id = excluded.project_id,
    artifact_digest = excluded.artifact_digest,
    title = excluded.title,
    metadata = excluded.metadata,
    summary = excluded.summary,
    verified_findings = excluded.verified_findings,
    regressions = excluded.regressions,
    commit_timeline = excluded.commit_timeline,
    recommendations = excluded.recommendations,
    notes = excluded.notes,
    footer = excluded.footer;
