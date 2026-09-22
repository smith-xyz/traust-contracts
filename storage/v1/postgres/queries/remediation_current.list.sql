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
FROM traust_storage.remediation_current
WHERE scope_id IN (
    SELECT jsonb_array_elements_text(%(scope_ids)s::jsonb)
)
ORDER BY scope_id, subject_id, finding_ref;
