-- Compliance posture: control verdicts of the CURRENT assessment, with the
-- owner of the subject assessed.
--
-- One row per control per framework, never an aggregate: a posture rollup
-- that reports "72% satisfied" and cannot name the unsatisfied controls is
-- not an assessment, and the control list is what an auditor asks for
-- first. A consumer wanting the percentage groups this; a consumer wanting
-- the gaps filters it.
--
-- verdict_source is carried UNCOLLAPSED. Satisfied-by-check,
-- satisfied-by-agent and satisfied-by-human-override are three different
-- assurance claims, and `assurance_tier` orders them so a consumer can sort
-- without restating the rule:
--   1  check            a deterministic collector said so
--   2  agent            an agent read evidence and judged
--   3  human_override   a person set the check's verdict aside
--
-- Ownership is LEFT JOINed for the reason ownership always is here: an
-- assessment of a subject the registry does not declare is still real, it
-- simply has no denominator.
--
-- Supersession follows current_binding: the newest assessment of a subject
-- wins, which is the rule report_current and threat_current already apply.
CREATE VIEW IF NOT EXISTS compliance_posture AS
SELECT b.scope_id,
       b.subject_id,
       b.run_id,
       r.framework,
       r.control_id,
       r.title,
       r.classification,
       r.verdict,
       r.verdict_source,
       CASE r.verdict_source
           WHEN 'check' THEN 1
           WHEN 'agent' THEN 2
           WHEN 'human_override' THEN 3
       END AS assurance_tier,
       r.check_id,
       r.reason,
       r.narrative,
       r.evidence,
       r.override,
       r.n_pass_agreement,
       owner.ownership,
       owner.business_unit,
       owner.tree,
       owner.product,
       owner.is_branch_audit
FROM compliance_result r
JOIN current_binding b
  ON b.binding_id = r.binding_id
LEFT JOIN ownership_current owner
  ON owner.subject_id = b.subject_id;
