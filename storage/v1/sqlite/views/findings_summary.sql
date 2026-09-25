-- Provisional findings summary for the Security Posture dashboard; not the future compliance posture dashboard.
CREATE VIEW IF NOT EXISTS findings_summary AS
SELECT finding_binding.scope_id,
       finding_binding.subject_id,
       finding_binding.run_id,
       finding_binding.layer_id,
       ownership.repo_url AS repo,
       finding.severity,
       triage.verdict,
       COUNT(DISTINCT finding.finding_id) AS finding_count
FROM current_binding finding_binding
JOIN finding finding
  ON finding.binding_id = finding_binding.binding_id
LEFT JOIN current_binding triage_binding
  ON triage_binding.scope_id = finding_binding.scope_id
 AND triage_binding.subject_id = finding_binding.subject_id
 AND triage_binding.run_id = finding_binding.run_id
 AND triage_binding.artifact_name = 'triage'
LEFT JOIN triage_verdict triage
  ON triage.binding_id = triage_binding.binding_id
 AND triage.source_finding_id = finding.finding_id
LEFT JOIN ownership_current ownership
  ON ownership.scope_id = finding_binding.scope_id
 AND ownership.subject_id = finding_binding.subject_id
WHERE finding_binding.artifact_name = 'vuln-findings'
GROUP BY finding_binding.scope_id,
         finding_binding.subject_id,
         finding_binding.run_id,
         finding_binding.layer_id,
         ownership.repo_url,
         finding.severity,
         triage.verdict;
