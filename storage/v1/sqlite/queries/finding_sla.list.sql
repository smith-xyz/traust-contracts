SELECT scope_id,
       fingerprint,
       severity,
       ownership,
       business_unit,
       tree,
       first_seen,
       resolved_at,
       still_open,
       age_days,
       days_to_resolve
FROM finding_sla
WHERE scope_id IN (SELECT value FROM json_each(:scope_ids))
ORDER BY scope_id, age_days DESC;
