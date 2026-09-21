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
CREATE VIEW IF NOT EXISTS validation_current AS
SELECT b.scope_id,
       b.subject_id,
       b.run_id,
       json_extract(v.metadata, '$.target_environment') AS environment,
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
FROM validation_finding vf
JOIN artifact_binding b
  ON b.binding_id = vf.binding_id
JOIN validation v
  ON v.binding_id = vf.binding_id
LEFT JOIN ownership_current owner
  ON owner.subject_id = b.subject_id
WHERE b.artifact_name = 'validation'
  AND NOT EXISTS (
      SELECT 1
      FROM artifact_binding rival
      JOIN validation rv ON rv.binding_id = rival.binding_id
      WHERE rival.artifact_name = 'validation'
        AND rival.scope_id = b.scope_id
        AND rival.subject_id = b.subject_id
        AND COALESCE(json_extract(rv.metadata, '$.target_environment'), rival.run_id)
          = COALESCE(json_extract(v.metadata, '$.target_environment'), b.run_id)
        AND (rival.bound_at > b.bound_at
             OR (rival.bound_at = b.bound_at AND rival.binding_id > b.binding_id))
  );
