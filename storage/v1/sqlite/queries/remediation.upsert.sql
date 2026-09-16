INSERT INTO remediation (
    binding_id,
    artifact_digest,
    title,
    metadata,
    source_findings,
    fork,
    patch,
    checks,
    revalidation,
    pull_request,
    summary,
    notes,
    footer
) VALUES (
    :binding_id,
    :artifact_digest,
    :title,
    :metadata,
    :source_findings,
    :fork,
    :patch,
    :checks,
    :revalidation,
    :pull_request,
    :summary,
    :notes,
    :footer
)
ON CONFLICT (binding_id) DO NOTHING;
