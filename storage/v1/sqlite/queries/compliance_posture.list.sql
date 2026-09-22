SELECT scope_id,
       subject_id,
       run_id,
       framework,
       control_id,
       title,
       classification,
       verdict,
       verdict_source,
       assurance_tier,
       check_id,
       reason,
       narrative,
       evidence,
       override,
       n_pass_agreement,
       ownership,
       business_unit,
       tree,
       product,
       is_branch_audit
FROM compliance_posture
WHERE scope_id IN (SELECT value FROM json_each(:scope_ids))
ORDER BY scope_id, framework, control_id, subject_id;
