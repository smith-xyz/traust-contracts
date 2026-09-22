-- Census population: the denominator, per tree.
--
-- Counted from subject_ownership rather than from findings, because a
-- subject with no findings is still coverage -- and a denominator that
-- only counts repos that happen to have a finding is the classic way to
-- overstate a percentage.
--
-- `with_report` is how many of those subjects actually produced a current
-- report, which is the coverage numerator.
CREATE OR REPLACE VIEW traust_storage.census_population AS
SELECT owner.scope_id,
       owner.tree,
       owner.ownership,
       owner.business_unit,
       COUNT(*) AS subjects,
       SUM(CASE WHEN owner.is_branch_audit = 1 THEN 1 ELSE 0 END) AS branch_reaudits,
       SUM(CASE WHEN reported.subject_id IS NULL THEN 0 ELSE 1 END) AS with_report
FROM traust_storage.ownership_current owner
LEFT JOIN (
    SELECT DISTINCT scope_id, subject_id FROM traust_storage.current_finding
) reported
  ON reported.scope_id = owner.scope_id
 AND reported.subject_id = owner.subject_id
GROUP BY owner.scope_id, owner.tree, owner.ownership, owner.business_unit;
