INSERT INTO cloud_config_findings_current (
    binding_id,
    artifact_digest,
    title,
    metadata,
    summary,
    findings,
    gaps,
    disposition_summary
) VALUES (
    %(binding_id)s,
    %(artifact_digest)s,
    %(title)s,
    %(metadata)s,
    %(summary)s,
    %(findings)s,
    %(gaps)s,
    %(disposition_summary)s
)
ON CONFLICT (binding_id) DO NOTHING;
