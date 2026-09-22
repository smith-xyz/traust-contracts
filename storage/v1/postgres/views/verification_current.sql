-- Did the fix hold: one row per re-audited finding of the CURRENT
-- verification, with the owner of the subject.
--
-- `verdict` keeps all SEVEN contract values. Folding to fixed/not-fixed
-- reports partially_resolved and new_approach as one of the two things they
-- are not, and false_positive and risk_accepted as failures when neither is
-- a fix that failed.
--
-- `held` is the derived binary beside it, and it is deliberately narrow:
-- ONLY `resolved`. A false_positive means the original finding was not real,
-- so nothing held; risk_accepted means nobody fixed it. Both are reasonable
-- outcomes and neither is evidence that a fix worked, which is the single
-- question `held` answers.
--
-- `unattributed` rides along because it is evidence about the evidence: a
-- fix nobody could tie to a commit. Without it an unexplained pass reads
-- exactly like a demonstrated one.
--
-- Regressions are NOT here. They are new findings the fix introduced and
-- live in verification_regression; counting them as verified findings would
-- make "how many findings did this verification touch" ambiguous.
CREATE OR REPLACE VIEW traust_storage.verification_current AS
SELECT b.scope_id,
       b.subject_id,
       b.run_id,
       f.original_id,
       f.original_title,
       f.original_severity,
       f.verdict,
       CASE WHEN f.verdict = 'resolved' THEN 1 ELSE 0 END AS held,
       f.unattributed,
       f.remediation_commits,
       f.evidence_explanation,
       f.evidence_framework_reference,
       f.evidence_original_code,
       f.evidence_patched_code,
       f.disposition_rationale,
       f.residual_risk,
       f.residual_severity,
       f.cross_repo,
       owner.ownership,
       owner.business_unit,
       owner.tree,
       owner.product,
       owner.is_branch_audit
FROM traust_storage.verification_finding f
JOIN traust_storage.current_binding b
  ON b.binding_id = f.binding_id
LEFT JOIN traust_storage.ownership_current owner
  ON owner.subject_id = b.subject_id;
