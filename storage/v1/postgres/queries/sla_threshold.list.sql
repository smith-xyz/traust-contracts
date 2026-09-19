SELECT scope_id,
       policy_name,
       profile_name,
       clock_start,
       severity,
       resolve_days,
       acknowledge_days
FROM traust_storage.sla_threshold
WHERE scope_id IN (
    SELECT jsonb_array_elements_text(%(scope_ids)s::jsonb)
)
ORDER BY scope_id, severity;
