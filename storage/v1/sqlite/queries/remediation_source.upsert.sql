INSERT INTO remediation_source (
    binding_id,
    artifact_digest,
    finding_ref,
    title,
    severity,
    cwes,
    locations,
    triage_confidence,
    validation_verdict,
    audit_report_path,
    triage_report_path,
    validation_report_path
)
VALUES (
    :binding_id,
    :artifact_digest,
    :finding_ref,
    :title,
    :severity,
    :cwes,
    :locations,
    :triage_confidence,
    :validation_verdict,
    :audit_report_path,
    :triage_report_path,
    :validation_report_path
)
ON CONFLICT (binding_id, finding_ref) DO NOTHING;
