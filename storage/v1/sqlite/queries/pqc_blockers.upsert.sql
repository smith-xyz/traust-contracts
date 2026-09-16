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
    :binding_id,
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
ON CONFLICT (binding_id) DO NOTHING;
