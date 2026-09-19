-- SLA clock per open finding: how long it has been open, and against what.
--
-- Age runs from FIRST OBSERVED, not from first adjudication -- the clock a
-- service-level commitment is judged on starts when the problem existed,
-- not when someone got round to triaging it.
--
-- Still-open findings carry age and no resolution date. Reporting only
-- CLOSED findings is the classic way an SLA dashboard looks healthy: the
-- breaches are precisely the ones that never closed, so excluding them
-- inverts the metric.
--
-- The threshold is NOT hardcoded. sla_policy is a contract artifact and a
-- deployment sets its own; joining it here means an adopter changes policy
-- without touching this view. No policy ingested means NULL threshold and
-- NULL breach -- unknown, never a silent pass.
CREATE VIEW IF NOT EXISTS finding_sla AS
SELECT t.scope_id,
       t.fingerprint,
       c.severity,
       c.ownership,
       c.business_unit,
       c.tree,
       t.first_seen,
       t.resolved_at,
       CASE WHEN t.resolved_at IS NULL THEN 1 ELSE 0 END AS still_open,
       COALESCE(t.days_to_resolve,
                julianday(t.last_seen) - julianday(t.first_seen)) AS age_days,
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
) c ON c.scope_id = t.scope_id AND c.fingerprint = t.fingerprint;
