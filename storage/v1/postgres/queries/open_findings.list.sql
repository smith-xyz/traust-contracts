SELECT scope_id,
       subject_id,
       run_id,
       finding_id,
       title,
       severity,
       fingerprint,
       validity,
       resolution,
       assurance,
       family,
       ownership,
       business_unit,
       tree,
       is_branch_audit
FROM traust_storage.open_findings
WHERE scope_id IN (
    SELECT jsonb_array_elements_text(%(scope_ids)s::jsonb)
)
ORDER BY scope_id, subject_id, run_id, finding_id, title;
