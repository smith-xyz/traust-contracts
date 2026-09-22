SELECT scope_id,
       subject_id,
       run_id,
       target_environment,
       source_id,
       source_finding_id,
       title,
       claimed_severity,
       surface,
       verdict,
       skip_reason,
       technique,
       observed_impact,
       evidence_grade,
       grade_rationale,
       soundness_flag,
       severity_validation,
       deviation_from_claim,
       rollback_performed,
       chain_context,
       not_attempted_reason,
       ownership,
       business_unit,
       tree,
       product,
       is_branch_audit
FROM traust_storage.validation_current
WHERE scope_id IN (
    SELECT jsonb_array_elements_text(%(scope_ids)s::jsonb)
)
ORDER BY scope_id, subject_id, target_environment, source_id;
