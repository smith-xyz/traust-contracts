SELECT scope_id,
       subject_id,
       run_id,
       original_id,
       original_title,
       original_severity,
       verdict,
       held,
       unattributed,
       remediation_commits,
evidence_explanation,
       evidence_framework_reference,
       evidence_original_code,
       evidence_patched_code,
       disposition_rationale,
       residual_risk,
       residual_severity,
       cross_repo,
       ownership,
       business_unit,
       tree,
       product,
       is_branch_audit
FROM traust_storage.verification_current
WHERE scope_id IN (
    SELECT jsonb_array_elements_text(%(scope_ids)s::jsonb)
)
ORDER BY scope_id, subject_id, original_id;
