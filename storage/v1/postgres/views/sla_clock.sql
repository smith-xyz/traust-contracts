-- The policy-level SLA clock, one row per scope.
--
-- Separate from sla_threshold ON PURPOSE. clock_start is a property of
-- the POLICY, not of a severity, and resolving it through the per-severity
-- join meant a severity the profile does not clock fell back to a
-- different clock than its siblings. Measured on a live corpus, findings
-- split roughly evenly between ageing from the report date and the ledger
-- event, under one policy that names a single clock.
--
-- A severity may legitimately have no threshold (unclocked) while the
-- policy still says where every clock starts.
CREATE OR REPLACE VIEW traust_storage.sla_clock AS
SELECT b.scope_id,
       p.policy_name,
       profile.key AS profile_name,
       COALESCE(p.clock_start, 'first_routed_or_filed') AS clock_start
FROM traust_storage.sla_policy p
JOIN traust_storage.current_binding b ON b.binding_id = p.binding_id
JOIN LATERAL jsonb_each(p.profiles) profile ON TRUE
WHERE (profile.value->>'default')::boolean IS TRUE;
