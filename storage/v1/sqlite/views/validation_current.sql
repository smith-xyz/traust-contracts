-- Current live-validation outcomes, one row per claimed finding, with the
-- owner of the subject they were validated against.
--
-- EVERY FIELD THE CONTRACT DECLARES ON A VALIDATED FINDING IS CARRIED.
-- The first cut dropped `evidence_grade` (E0-E3)
-- and `soundness_flag` -- the machine-readable reason a refutation was
-- un-emittable. Those two say how far a verdict can be trusted, and a
-- view reporting outcomes without them gives no way to weigh them.
-- Projected as columns, never joined out of the blob: matching
-- source_id against every entry of the same array is quadratic per
-- artifact. tests/test_view_contract_coverage.py enforces the coverage.
--
-- SUPERSESSION IS PER ENVIRONMENT, NOT PER SUBJECT. A run against a hub
-- cluster and a run against a spoke are not re-runs of each other. Measured
-- measured: one subject's hub and spoke runs covered the SAME findings
-- and disagreed on a material share of the verdicts, some confirmed
-- against one target and refuted against the other. Collapsing on
-- subject alone silently
-- picked one and deleted the disagreement, which is the single most
-- interesting thing the evidence lens has to say.
--
-- `metadata.environment` is extracted rather than stored a second time,
-- the way operator_privilege reads its summary counts out of JSON.
--
-- ABSENT ENVIRONMENT MEANS UNKNOWN, NOT "THE SAME AS THE OTHERS". The
-- partition falls back to run_id, so every run of an unlabelled subject
-- stays distinct rather than being merged on an assumption. That is
-- deliberately noisier: many artifacts predate the field, and merging
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
       json_extract(v.metadata, '$.target_environment') AS target_environment,
       vf.source_id,
       vf.source_finding_id,
       vf.title,
       vf.claimed_severity,
       vf.surface,
       vf.verdict,
       vf.skip_reason,
       vf.technique,
       vf.observed_impact,
       vf.evidence_grade,
       vf.grade_rationale,
       vf.soundness_flag,
       vf.severity_validation,
       vf.deviation_from_claim,
       vf.rollback_performed,
       vf.chain_context,
       vf.not_attempted_reason,
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
