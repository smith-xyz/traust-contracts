INSERT INTO traust_storage.compliance_result (
    binding_id,
    artifact_digest,
    framework,
    control_id,
    title,
    classification,
    verdict,
    verdict_source,
    check_id,
    reason,
    narrative,
    evidence,
    override,
    n_pass_agreement
)
VALUES (
    %(binding_id)s,
    %(artifact_digest)s,
    %(framework)s,
    %(control_id)s,
    %(title)s,
    %(classification)s,
    %(verdict)s,
    %(verdict_source)s,
    %(check_id)s,
    %(reason)s,
    %(narrative)s,
    %(evidence)s,
    %(override)s,
    %(n_pass_agreement)s
)
ON CONFLICT (binding_id, framework, control_id) DO NOTHING;
