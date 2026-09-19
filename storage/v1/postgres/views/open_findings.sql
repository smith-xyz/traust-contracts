-- Open exposure: the census convention, expressed on the contract.
--
-- "Open" is anything not AFFIRMATIVELY closed, so partial fixes and
-- regressions still count as shipped exposure. False positives are not
-- real and hardening is posture debt tracked separately, so both come out.
--
-- The value lists are GENERATED from the contract enums, never typed: the
-- harness projection once excluded 'in_progress' where the enum says
-- 'fix_in_progress', and every in-progress finding silently vanished. A
-- test asserts these lists still match the enums.
CREATE OR REPLACE VIEW traust_storage.open_findings AS
SELECT scope_id, subject_id, run_id, finding_id, title, severity,
       fingerprint, validity, resolution, assurance, family,
       ownership, business_unit, tree, is_branch_audit
FROM traust_storage.current_finding
WHERE COALESCE(resolution, 'open') NOT IN ('resolved', 'risk_accepted')
  AND COALESCE(validity, 'confirmed') NOT IN ('false_positive', 'hardening');
