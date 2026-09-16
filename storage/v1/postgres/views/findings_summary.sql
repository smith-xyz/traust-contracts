-- Provisional findings summary for the Security Posture dashboard; not the future compliance posture dashboard.
CREATE OR REPLACE VIEW findings_summary WITH (security_barrier) AS
SELECT finding_binding.scope_id,
       finding_binding.subject_id,
       finding_binding.run_id,
       finding_binding.layer_id,
       layer_metadata.repo,
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
LEFT JOIN current_binding layer_binding
  ON layer_binding.scope_id = finding_binding.scope_id
 AND layer_binding.layer_id = finding_binding.layer_id
 AND layer_binding.artifact_name = 'layer'
LEFT JOIN layer_metadata
  ON layer_metadata.binding_id = layer_binding.binding_id
WHERE finding_binding.artifact_name = 'vuln-findings'
  AND finding_binding.scope_id IN (
      SELECT jsonb_array_elements_text(
          COALESCE(current_setting('traust.scope_ids', true), '[]')::jsonb
      )
  )
GROUP BY finding_binding.scope_id,
         finding_binding.subject_id,
         finding_binding.run_id,
         finding_binding.layer_id,
         layer_metadata.repo,
         finding.severity,
         triage.verdict;
