-- SLA state per finding, judged against the DEPLOYMENT'S OWN policy.
--
-- Nothing here is hardcoded. The threshold, the profile and the clock
-- start all come from the sla-policy artifact, so an adopter states their
-- numbers once and every consumer inherits them -- which is the point: a
-- dashboard that reimplements thresholds is a second place for them to be
-- wrong.
--
-- CLOCK START is policy, not opinion. The same finding has three
-- defensible start times and they give different answers:
--   audit_date              when a scanner first reported it
--   first_event             when someone first adjudicated it
--   first_routed_or_filed   when it reached a tracker or review (default),
--                           falling back to first_event, then audit_date
--
-- Still-open findings are INCLUDED. The breaches are precisely the ones
-- that never closed, so a closed-only SLA view inverts the metric it
-- claims to report.
--
-- No policy ingested means NULL threshold and NULL breached -- unknown,
-- never a silent pass. resolve_days NULL is a real policy position
-- ("tracked, never overdue") and also yields NULL breached, never false.
CREATE VIEW IF NOT EXISTS finding_sla AS
SELECT t.scope_id,
       t.fingerprint,
       c.severity,
       c.ownership,
       c.business_unit,
       c.tree,
       policy.policy_name,
       policy.profile_name,
       COALESCE(policy.clock_start, 'audit_date') AS clock_start,
       CASE COALESCE(policy.clock_start, 'audit_date')
            WHEN 'first_event' THEN COALESCE(t.first_adjudicated, t.first_seen)
            WHEN 'first_routed_or_filed'
                 THEN COALESCE(t.first_routed_or_filed, t.first_adjudicated,
                               t.first_seen)
            ELSE t.first_seen
       END AS clock_started_at,
       t.resolved_at,
       CASE WHEN t.resolved_at IS NULL THEN 1 ELSE 0 END AS still_open,
       policy.resolve_days,
       julianday(COALESCE(t.resolved_at, t.last_seen))
           - julianday(CASE COALESCE(policy.clock_start, 'audit_date')
                WHEN 'first_event' THEN COALESCE(t.first_adjudicated, t.first_seen)
                WHEN 'first_routed_or_filed'
                     THEN COALESCE(t.first_routed_or_filed, t.first_adjudicated,
                                   t.first_seen)
                ELSE t.first_seen
           END) AS age_days,
       CASE WHEN policy.resolve_days IS NULL THEN NULL
            WHEN julianday(COALESCE(t.resolved_at, t.last_seen))
                 - julianday(CASE COALESCE(policy.clock_start, 'audit_date')
                      WHEN 'first_event' THEN COALESCE(t.first_adjudicated, t.first_seen)
                      WHEN 'first_routed_or_filed'
                           THEN COALESCE(t.first_routed_or_filed, t.first_adjudicated,
                                         t.first_seen)
                      ELSE t.first_seen
                 END) > policy.resolve_days
            THEN 1 ELSE 0
       END AS breached,
       t.days_to_resolve
FROM finding_timeline t
JOIN (
    SELECT scope_id, fingerprint,
           MIN(severity) AS severity,
           MIN(ownership) AS ownership,
           MIN(business_unit) AS business_unit,
           MIN(tree) AS tree
    FROM current_finding
    WHERE fingerprint IS NOT NULL
      AND COALESCE(validity, 'confirmed') NOT IN ('false_positive', 'hardening')
    GROUP BY scope_id, fingerprint
) c ON c.scope_id = t.scope_id AND c.fingerprint = t.fingerprint
LEFT JOIN sla_threshold policy
       ON policy.scope_id = t.scope_id AND policy.severity = c.severity;
