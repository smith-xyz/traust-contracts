-- What each remediation set out to fix: one row per source finding of the
-- CURRENT remediation, with the owner.
--
-- The join that was missing. A remediation names the findings that
-- justified it, but they lived in a JSON column, so "which open findings
-- already have a fix in flight" had no answer in SQL and a reviewer had to
-- read the artifact.
--
-- `validation_verdict` is the state AT REMEDIATION TIME. It says why the
-- work was started; the finding's CURRENT disposition is on
-- current_finding, and reading this one as current is the mistake the
-- column name is trying to prevent.
CREATE VIEW IF NOT EXISTS remediation_current AS
SELECT b.scope_id,
       b.subject_id,
       b.run_id,
       s.finding_ref,
       s.title,
       s.severity,
       s.cwes,
       s.locations,
       s.triage_confidence,
       s.validation_verdict,
       s.audit_report_path,
       s.triage_report_path,
       s.validation_report_path,
       owner.ownership,
       owner.business_unit,
       owner.tree,
       owner.product,
       owner.is_branch_audit
FROM remediation_source s
JOIN current_binding b
  ON b.binding_id = s.binding_id
LEFT JOIN ownership_current owner
  ON owner.subject_id = b.subject_id;
