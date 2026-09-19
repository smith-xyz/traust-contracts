-- Current threats, with the owner of the subject they were modelled against.
--
-- threat-register is an aggregate that restates the WHOLE threat population
-- on every regeneration, exactly like corpus-registry -- so its rows
-- ACCUMULATE across bindings and a view reading the `threat` table raw
-- would multiply every threat count by the number of times the register had
-- been imported. This applies the same rule ownership_current does: the most
-- recently bound register wins, binding_id breaking ties.
--
-- Ownership is LEFT JOINed because a threat model can exist for a subject
-- the corpus registry does not declare; such a threat is still real, it
-- simply has no denominator, and dropping it would hide it entirely.
CREATE OR REPLACE VIEW traust_storage.threat_current AS
SELECT b.scope_id,
       t.threat_key,
       t.threat_id,
       t.model,
       t.subject_id,
       t.product,
       t.statement,
       t.surface,
       t.asset,
       t.impact,
       t.likelihood,
       t.status,
       t.controls,
       t.evidence,
       t.linddun,
       t.score,
       t.isolation_dimensions,
       t.isolation_boundaries,
       owner.ownership,
       owner.business_unit,
       owner.tree,
       owner.is_branch_audit
FROM traust_storage.threat t
JOIN traust_storage.artifact_binding b
  ON b.binding_id = t.binding_id
LEFT JOIN traust_storage.ownership_current owner
  ON owner.subject_id = t.subject_id
WHERE NOT EXISTS (
    SELECT 1
    FROM traust_storage.threat rival
    JOIN traust_storage.artifact_binding rival_binding
      ON rival_binding.binding_id = rival.binding_id
    WHERE rival.threat_key = t.threat_key
      AND rival_binding.scope_id = b.scope_id
      AND (rival_binding.bound_at > b.bound_at
           OR (rival_binding.bound_at = b.bound_at
               AND rival_binding.binding_id > b.binding_id))
);
