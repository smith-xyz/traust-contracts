-- Current live-validation outcomes, one row per claimed finding, with the
-- owner of the subject they were validated against.
--
-- A subject is re-validated as the lane re-runs, and an old run must not
-- count beside the new one. Same rule report_current and threat_current
-- apply: most recently bound wins, binding_id breaking ties so the answer
-- never depends on nothing.
--
-- `verdict` is carried UNCOLLAPSED, and the reason is not stylistic.
-- `not_attempted` dominates the corpus, so a view that reported only
-- attempts would describe a fraction of the lane's own work and read as
-- though the rest had been refuted. `skip_reason` travels with it: "no
-- adapter for this surface" and "triage already called it a false
-- positive" are different facts about why nothing was tried.
--
-- Ownership is LEFT JOINed: a validation can exist for a subject the
-- corpus registry does not declare. Such a run is still real; it simply
-- has no denominator.
CREATE VIEW IF NOT EXISTS validation_current AS
SELECT b.scope_id,
       b.subject_id,
       b.run_id,
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
LEFT JOIN ownership_current owner
  ON owner.subject_id = b.subject_id
WHERE b.artifact_name = 'validation'
  AND NOT EXISTS (
      SELECT 1
      FROM artifact_binding rival
      WHERE rival.artifact_name = 'validation'
        AND rival.scope_id = b.scope_id
        AND rival.subject_id = b.subject_id
        AND (rival.bound_at > b.bound_at
             OR (rival.bound_at = b.bound_at AND rival.binding_id > b.binding_id))
  );
