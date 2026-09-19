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
FROM open_findings
WHERE scope_id IN (SELECT value FROM json_each(:scope_ids))
ORDER BY scope_id, subject_id, run_id, finding_id, title;
