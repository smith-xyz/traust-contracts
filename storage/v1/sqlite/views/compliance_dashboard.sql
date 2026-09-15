CREATE VIEW IF NOT EXISTS compliance_dashboard AS
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
GROUP BY r.project_id, f.layer_id, r.repo,
         f.severity, t.verdict;
