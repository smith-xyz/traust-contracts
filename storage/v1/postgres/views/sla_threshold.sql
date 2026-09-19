-- Per-severity SLA thresholds from the deployment's OWN policy.
--
-- SLAs are policy data, never code. sla-policy is a contract artifact, so
-- an adopter states their own numbers, their own severity mapping and
-- their own clock start, and a per-business-unit policy is a different
-- binding rather than a fork of this view.
--
-- The DEFAULT profile is selected here. A deployment ships several
-- (baseline, a stricter contractual one, a regulated one) and marks one
-- default; picking a non-default profile is a query-time choice, not a
-- schema change.
--
-- resolve_days NULL means TRACKED BUT NEVER OVERDUE, which is a real
-- policy position and must not read as zero days. A severity absent from
-- the profile is unclocked under it, so it yields no row at all rather
-- than a fabricated threshold.
CREATE OR REPLACE VIEW traust_storage.sla_threshold AS
SELECT b.scope_id,
       p.policy_name,
       profile.key AS profile_name,
       COALESCE(p.clock_start, 'first_routed_or_filed') AS clock_start,
       sla.key AS severity,
       (sla.value->>'resolve_days')::int AS resolve_days,
       (sla.value->>'acknowledge_days')::int AS acknowledge_days
FROM traust_storage.sla_policy p
JOIN traust_storage.current_binding b ON b.binding_id = p.binding_id
JOIN LATERAL jsonb_each(p.profiles) profile ON TRUE
JOIN LATERAL jsonb_each(profile.value->'slas') sla ON TRUE
WHERE (profile.value->>'default')::boolean IS TRUE;
