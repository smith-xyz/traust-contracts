INSERT INTO traust_storage.validation (
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
    %(binding_id)s,
    %(artifact_digest)s,
    %(title)s,
    %(metadata)s,
    %(source_reports)s,
    %(summary)s,
    %(validated_findings)s,
    %(attack_chains)s,
    %(novel_findings)s,
    %(negative_results)s,
    %(execution_log_ref)s,
    %(execution_log_sha256)s,
    %(footer)s
)
ON CONFLICT (binding_id) DO NOTHING;
