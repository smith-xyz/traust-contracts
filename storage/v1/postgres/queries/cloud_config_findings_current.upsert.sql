INSERT INTO cloud_config_findings_current (
    layer_id,
    project_id,
    artifact_digest,
    title,
    metadata,
    summary,
    findings,
    gaps,
    disposition_summary
) VALUES (
    %(layer_id)s,
    %(project_id)s,
    %(artifact_digest)s,
    %(title)s,
    %(metadata)s,
    %(summary)s,
    %(findings)s,
    %(gaps)s,
    %(disposition_summary)s
)
ON CONFLICT (layer_id) DO UPDATE SET
    project_id = excluded.project_id,
    artifact_digest = excluded.artifact_digest,
    title = excluded.title,
    metadata = excluded.metadata,
    summary = excluded.summary,
    findings = excluded.findings,
    gaps = excluded.gaps,
    disposition_summary = excluded.disposition_summary;
