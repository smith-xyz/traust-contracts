INSERT INTO pqc_blockers (
    binding_id,
    artifact_digest,
    artifact,
    title,
    metadata,
    executive_summary,
    severity_criteria,
    findings,
    findings_summary,
    remediation_roadmap
) VALUES (
    %(binding_id)s,
    %(artifact_digest)s,
    %(artifact)s,
    %(title)s,
    %(metadata)s,
    %(executive_summary)s,
    %(severity_criteria)s,
    %(findings)s,
    %(findings_summary)s,
    %(remediation_roadmap)s
)
ON CONFLICT (binding_id) DO NOTHING;
