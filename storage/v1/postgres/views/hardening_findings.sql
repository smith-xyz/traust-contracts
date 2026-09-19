-- Posture debt: accurately-described defence-in-depth gaps with no
-- concrete exploit path. Real and risk-bearing, never a false positive,
-- and kept out of open exposure so the two are never blended.
CREATE OR REPLACE VIEW traust_storage.hardening_findings AS
SELECT scope_id, subject_id, run_id, finding_id, title, severity,
       fingerprint, validity, resolution, assurance, family,
       ownership, business_unit, tree, is_branch_audit
FROM traust_storage.current_finding
WHERE validity = 'hardening';
