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
    %(layer_id)s,
    %(project_id)s,
    %(artifact_digest)s,
    %(title)s,
    %(metadata)s,
    %(summary)s,
    %(verified_findings)s,
    %(regressions)s,
    %(commit_timeline)s,
    %(recommendations)s,
    %(notes)s,
    %(footer)s
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
