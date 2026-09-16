INSERT INTO remediation (
    binding_id,
    artifact_digest,
    title,
    metadata,
    source_findings,
    fork,
    patch,
    checks,
    evidence,
    revalidation,
    pull_request,
    summary,
    notes,
    footer
) VALUES (
    %(binding_id)s,
    %(artifact_digest)s,
    %(title)s,
    %(metadata)s,
    %(source_findings)s,
    %(fork)s,
    %(patch)s,
    %(checks)s,
    %(evidence)s,
    %(revalidation)s,
    %(pull_request)s,
    %(summary)s,
    %(notes)s,
    %(footer)s
)
ON CONFLICT (binding_id) DO NOTHING;
