-- Branch re-audits against HEAD, per tree: the census's second
-- duplication vector.
--
-- A branch re-audit restates the code HEAD was audited at. Its findings
-- are either CONFIRMATIONS of a HEAD finding (Lens 1 coverage, never new
-- exposure) or branch-only. The census computed this by holding every
-- HEAD fingerprint per tree in memory and walking every branch report; it
-- is a self-join on the spine.
--
-- False positives and hardening are excluded on both sides, so a
-- confirmation means a confirmed VULNERABILITY -- the same rule the
-- executive summary applies.
CREATE VIEW IF NOT EXISTS census_branch AS
SELECT branch.scope_id,
       branch.tree,
       branch.report_kind,
       COUNT(*) AS branch_findings,
       SUM(CASE WHEN head.fingerprint IS NULL THEN 0 ELSE 1 END) AS head_confirmations,
       COUNT(DISTINCT CASE WHEN head.fingerprint IS NULL THEN branch.fingerprint END)
           AS branch_only_distinct
FROM current_finding branch
LEFT JOIN (
    SELECT DISTINCT scope_id, tree, fingerprint
    FROM current_finding
    WHERE is_branch_audit = 0
      AND fingerprint IS NOT NULL
      AND COALESCE(validity, 'confirmed') NOT IN ('false_positive', 'hardening')
) head
  ON head.scope_id = branch.scope_id
 AND head.tree = branch.tree
 AND head.fingerprint = branch.fingerprint
WHERE branch.is_branch_audit = 1
  AND COALESCE(branch.validity, 'confirmed') NOT IN ('false_positive', 'hardening')
GROUP BY branch.scope_id, branch.tree, branch.report_kind;
