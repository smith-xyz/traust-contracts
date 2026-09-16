INSERT INTO verification (
    binding_id,
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
    %(binding_id)s,
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
ON CONFLICT (binding_id) DO NOTHING;
