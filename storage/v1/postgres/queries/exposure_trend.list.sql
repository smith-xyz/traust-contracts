SELECT scope_id,
       period,
       opened,
       closed,
       net
FROM traust_storage.exposure_trend
WHERE scope_id IN (
    SELECT jsonb_array_elements_text(%(scope_ids)s::jsonb)
)
ORDER BY scope_id, period;
