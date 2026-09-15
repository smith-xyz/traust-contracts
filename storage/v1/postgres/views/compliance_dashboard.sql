CREATE OR REPLACE VIEW compliance_dashboard WITH (security_barrier) AS
SELECT r.project_id,
       f.layer_id,
       r.repo,
       f.severity AS severity,
       t.verdict,
       COUNT(DISTINCT f.finding_id) AS finding_count
FROM finding f
JOIN layer_metadata r ON r.layer_id = f.layer_id
LEFT JOIN triage_verdict t
  ON t.layer_id = f.layer_id AND t.source_finding_id = f.finding_id
WHERE r.project_id = ANY (current_setting('traust.project_ids')::text[])
GROUP BY r.project_id, f.layer_id, r.repo,
         f.severity, t.verdict;
