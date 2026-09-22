-- Current tenant boundaries, with the owner of the subject they were
-- modelled for and the ordering aids the register uses.
--
-- Same supersession rule as threat_current: one model per subject, most
-- recently bound wins, binding_id breaking ties.
--
-- `weakness` sums the failed (2) and partial (1) isolation dimensions; a
-- 'yes' or 'na' contributes nothing. `open_threats` counts the threats
-- tagged to the boundary whose status is unmitigated or
-- partially_mitigated IN THE SAME MODEL, joined through boundary_threat
-- rather than matched against the threat_ids array. Both are ORDERINGS
-- for a register, never a calibrated risk value.
CREATE OR REPLACE VIEW traust_storage.boundary_current AS
SELECT b.scope_id,
       tb.boundary_key,
       tb.boundary_id,
       tb.subject_id,
       tb.product,
       tb.interface,
       tb.kind,
       tb.exposure,
       tb.complexity,
       tb.privilege,
       tb.encryption,
       tb.authentication,
       tb.connectivity,
       tb.hygiene,
       tb.threat_ids,
       tb.isolation_review_ref,
       (CASE tb.privilege WHEN 'no' THEN 2 WHEN 'partial' THEN 1 ELSE 0 END
        + CASE tb.encryption WHEN 'no' THEN 2 WHEN 'partial' THEN 1 ELSE 0 END
        + CASE tb.authentication WHEN 'no' THEN 2 WHEN 'partial' THEN 1 ELSE 0 END
        + CASE tb.connectivity WHEN 'no' THEN 2 WHEN 'partial' THEN 1 ELSE 0 END
        + CASE tb.hygiene WHEN 'no' THEN 2 WHEN 'partial' THEN 1 ELSE 0 END) AS weakness,
       (SELECT COUNT(*)
        FROM traust_storage.boundary_threat bt
        JOIN traust_storage.threat t
          ON t.binding_id = bt.binding_id
         AND t.threat_id = bt.threat_id
        WHERE bt.binding_id = tb.binding_id
          AND bt.boundary_key = tb.boundary_key
          AND t.status IN ('unmitigated', 'partially_mitigated')) AS open_threats,
       owner.ownership,
       owner.business_unit,
       owner.tree,
       owner.is_branch_audit
FROM traust_storage.threat_boundary tb
JOIN traust_storage.artifact_binding b
  ON b.binding_id = tb.binding_id
LEFT JOIN traust_storage.ownership_current owner
  ON owner.subject_id = b.subject_id
WHERE b.artifact_name = 'threat-model'
  AND NOT EXISTS (
      SELECT 1
      FROM traust_storage.artifact_binding rival
      WHERE rival.artifact_name = 'threat-model'
        AND rival.scope_id = b.scope_id
        AND rival.subject_id = b.subject_id
        AND (rival.bound_at > b.bound_at
             OR (rival.bound_at = b.bound_at AND rival.binding_id > b.binding_id))
  );
