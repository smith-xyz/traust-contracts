SELECT scope_id,
       subject_id,
       run_id,
       layer_id,
       repo,
       severity,
       verdict,
       finding_count
FROM findings_summary
WHERE scope_id IN (SELECT value FROM json_each(:scope_ids))
ORDER BY scope_id, subject_id, run_id, layer_id, repo, severity, verdict;
