-- What the fix BROKE: one row per regression of the current verification.
--
-- Separate from verification_current because a regression is a new finding,
-- not a restatement of the one the fix closed. This is the half a
-- remediation review must not miss, and it was unreachable from SQL: the
-- regressions lived inside the verification blob.
--
-- `introduced_by` names the commit, and `routed_id` the finding it was
-- filed as when it was routed onward -- the join back into the ordinary
-- findings flow.
CREATE VIEW IF NOT EXISTS verification_regression_current AS
SELECT b.scope_id,
       b.subject_id,
       b.run_id,
       r.regression_id,
       r.title,
       r.severity,
       r.cwes,
       r.cvss,
       r.locations,
       r.description,
       r.remediation,
       r.evidence,
       r.attack_pattern,
       r.category,
       r.introduced_by,
       r.routed_id,
       r.fingerprint,
       r.fingerprint_algo,
       owner.ownership,
       owner.business_unit,
       owner.tree,
       owner.product,
       owner.is_branch_audit
FROM verification_regression r
JOIN current_binding b
  ON b.binding_id = r.binding_id
LEFT JOIN ownership_current owner
  ON owner.subject_id = b.subject_id;
