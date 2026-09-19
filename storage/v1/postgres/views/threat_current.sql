-- Current threats, with the owner of the subject they were modelled against.
--
-- threat-register is an aggregate that restates the WHOLE threat population
-- on every regeneration, exactly like corpus-registry, so its rows
-- ACCUMULATE across bindings; a view reading `threat` raw multiplies every
-- count by the number of imports.
--
-- Resolved per BINDING, not per threat. The first version of this view raced
-- rows against each other with a correlated NOT EXISTS on threat_key, which
-- is quadratic in the threat table -- measured on the live register it had
-- not finished after 44 minutes at 165,700 rows, and an index on threat_key
-- does not rescue it. Because the register is a whole-population
-- restatement, exactly one binding per scope is current, and that set is
-- tiny: pick it from artifact_binding first, then join. Linear, and it says
-- what is actually true about the artifact.
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
JOIN (
    SELECT scope_id, binding_id
    FROM traust_storage.artifact_binding current_register
    WHERE current_register.artifact_name = 'threat-register'
      AND NOT EXISTS (
          SELECT 1
          FROM traust_storage.artifact_binding rival
          WHERE rival.artifact_name = 'threat-register'
            AND rival.scope_id = current_register.scope_id
            AND (rival.bound_at > current_register.bound_at
                 OR (rival.bound_at = current_register.bound_at
                     AND rival.binding_id > current_register.binding_id))
      )
) b ON b.binding_id = t.binding_id
LEFT JOIN traust_storage.ownership_current owner
  ON owner.subject_id = t.subject_id;
