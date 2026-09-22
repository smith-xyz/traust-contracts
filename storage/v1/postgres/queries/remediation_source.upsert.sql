INSERT INTO traust_storage.remediation_source (
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
    %(binding_id)s,
    %(artifact_digest)s,
    %(finding_ref)s,
    %(title)s,
    %(severity)s,
    %(cwes)s,
    %(locations)s,
    %(triage_confidence)s,
    %(validation_verdict)s,
    %(audit_report_path)s,
    %(triage_report_path)s,
    %(validation_report_path)s
)
ON CONFLICT (binding_id, finding_ref) DO NOTHING;
