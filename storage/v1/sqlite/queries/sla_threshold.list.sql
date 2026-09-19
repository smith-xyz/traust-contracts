SELECT scope_id,
       policy_name,
       profile_name,
       clock_start,
       severity,
       resolve_days,
       acknowledge_days
FROM sla_threshold
WHERE scope_id IN (SELECT value FROM json_each(:scope_ids))
ORDER BY scope_id, severity;
