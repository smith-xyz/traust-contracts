SELECT scope_id,
       subject_id,
       run_id,
       layer_id,
       repo,
       severity,
       verdict,
       finding_count
FROM findings_summary
WHERE scope_id IN (
    SELECT jsonb_array_elements_text(%(scope_ids)s::jsonb)
)
ORDER BY scope_id, subject_id, run_id, layer_id, repo, severity, verdict;
