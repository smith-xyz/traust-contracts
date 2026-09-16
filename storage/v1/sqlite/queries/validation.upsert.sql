INSERT INTO validation (
    binding_id,
    artifact_digest,
    title,
    metadata,
    source_reports,
    summary,
    validated_findings,
    attack_chains,
    novel_findings,
    negative_results,
    execution_log_ref,
    execution_log_sha256,
    footer
) VALUES (
    :binding_id,
    :artifact_digest,
    :title,
    :metadata,
    :source_reports,
    :summary,
    :validated_findings,
    :attack_chains,
    :novel_findings,
    :negative_results,
    :execution_log_ref,
    :execution_log_sha256,
    :footer
)
ON CONFLICT (binding_id) DO NOTHING;
