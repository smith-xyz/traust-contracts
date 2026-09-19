SELECT scope_id,
       period,
       opened,
       closed,
       net
FROM exposure_trend
WHERE scope_id IN (SELECT value FROM json_each(:scope_ids))
ORDER BY scope_id, period;
