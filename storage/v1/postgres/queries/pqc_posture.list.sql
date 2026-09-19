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
FROM traust_storage.pqc_posture
WHERE scope_id IN (
    SELECT jsonb_array_elements_text(%(scope_ids)s::jsonb)
)
ORDER BY scope_id, subject_id;
