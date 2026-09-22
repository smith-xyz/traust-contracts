INSERT INTO compliance_result (
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
    :binding_id,
    :artifact_digest,
    :framework,
    :control_id,
    :title,
    :classification,
    :verdict,
    :verdict_source,
    :check_id,
    :reason,
    :narrative,
    :evidence,
    :override,
    :n_pass_agreement
)
ON CONFLICT (binding_id, framework, control_id) DO NOTHING;
