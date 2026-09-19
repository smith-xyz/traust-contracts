SELECT scope_id,
       fingerprint,
       severity,
       ownership,
       business_unit,
       tree,
       policy_name,
       profile_name,
       clock_start,
       clock_started_at,
       resolved_at,
       still_open,
       resolve_days,
       age_days,
       breached,
       days_to_resolve
FROM finding_sla
WHERE scope_id IN (SELECT value FROM json_each(:scope_ids))
ORDER BY scope_id, age_days DESC;
