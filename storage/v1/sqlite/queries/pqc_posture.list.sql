SELECT scope_id,
       subject_id,
       readiness_bucket,
       has_2030_clock,
       hndl_priority,
       runtime_verification_required,
       dominant_provenance,
       clock_items,
       ownership,
       business_unit,
       tree,
       is_branch_audit
FROM pqc_posture
WHERE scope_id IN (SELECT value FROM json_each(:scope_ids))
ORDER BY scope_id, subject_id;
