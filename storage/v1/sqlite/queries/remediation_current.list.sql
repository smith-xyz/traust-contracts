SELECT scope_id,
       subject_id,
       run_id,
       finding_ref,
       title,
       severity,
       cwes,
       locations,
       triage_confidence,
       validation_verdict,
       audit_report_path,
       triage_report_path,
       validation_report_path,
       ownership,
       business_unit,
       tree,
       product,
       is_branch_audit
FROM remediation_current
WHERE scope_id IN (SELECT value FROM json_each(:scope_ids))
ORDER BY scope_id, subject_id, finding_ref;
