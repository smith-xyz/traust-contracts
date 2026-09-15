INSERT INTO pqc_blockers (
    layer_id,
    project_id,
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
    :layer_id,
    :project_id,
    :artifact_digest,
    :artifact,
    :title,
    :metadata,
    :executive_summary,
    :severity_criteria,
    :findings,
    :findings_summary,
    :remediation_roadmap
)
ON CONFLICT (layer_id) DO UPDATE SET
    project_id = excluded.project_id,
    artifact_digest = excluded.artifact_digest,
    artifact = excluded.artifact,
    title = excluded.title,
    metadata = excluded.metadata,
    executive_summary = excluded.executive_summary,
    severity_criteria = excluded.severity_criteria,
    findings = excluded.findings,
    findings_summary = excluded.findings_summary,
    remediation_roadmap = excluded.remediation_roadmap;
