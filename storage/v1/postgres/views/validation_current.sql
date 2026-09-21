-- Current live-validation outcomes, one row per claimed finding, with the
-- owner of the subject they were validated against.
--
-- SUPERSESSION IS PER ENVIRONMENT, NOT PER SUBJECT. A run against a hub
-- cluster and a run against a spoke are not re-runs of each other. Measured
-- on the live corpus: one subject's hub and spoke runs covered the SAME
-- 3,297 findings and disagreed on 290 verdicts -- 48 confirmed against one
-- and refuted against the other. Collapsing on subject alone silently
-- picked one and deleted the disagreement, which is the single most
-- interesting thing the evidence lens has to say.
--
-- `metadata.environment` is extracted rather than stored a second time,
-- the way operator_privilege reads its summary counts out of JSON.
--
-- ABSENT ENVIRONMENT MEANS UNKNOWN, NOT "THE SAME AS THE OTHERS". The
-- partition falls back to run_id, so every run of an unlabelled subject
-- stays distinct rather than being merged on an assumption. That is
-- deliberately noisier: 1,231 artifacts predate the field, and merging
-- them is exactly the guess that produced the 290-verdict conflict. The
-- noise is the honest reading and it shrinks as producers adopt the field.
--
-- Within one environment the newest run wins, binding_id breaking ties --
-- the rule report_current and threat_current already apply.
--
-- Ownership is LEFT JOINed: a validation against a subject the registry
-- does not declare is still real; it simply has no denominator.
CREATE OR REPLACE VIEW traust_storage.validation_current WITH (security_barrier) AS
SELECT b.scope_id,
       b.subject_id,
       b.run_id,
       v.metadata->>'target_environment' AS target_environment,
       vf.source_id,
       vf.source_finding_id,
       vf.title,
       vf.claimed_severity,
       vf.surface,
       vf.verdict,
       vf.skip_reason,
       vf.technique,
       vf.observed_impact,
       owner.ownership,
       owner.business_unit,
       owner.tree,
       owner.product,
       owner.is_branch_audit
FROM traust_storage.validation_finding vf
JOIN traust_storage.artifact_binding b
  ON b.binding_id = vf.binding_id
JOIN traust_storage.validation v
  ON v.binding_id = vf.binding_id
LEFT JOIN traust_storage.ownership_current owner
  ON owner.subject_id = b.subject_id
WHERE b.artifact_name = 'validation'
  AND NOT EXISTS (
      SELECT 1
      FROM traust_storage.artifact_binding rival
      JOIN traust_storage.validation rv ON rv.binding_id = rival.binding_id
      WHERE rival.artifact_name = 'validation'
        AND rival.scope_id = b.scope_id
        AND rival.subject_id = b.subject_id
        AND COALESCE(rv.metadata->>'target_environment', rival.run_id)
          = COALESCE(v.metadata->>'target_environment', b.run_id)
        AND (rival.bound_at > b.bound_at
             OR (rival.bound_at = b.bound_at AND rival.binding_id > b.binding_id))
  );
