SELECT scope_id,
       fingerprint,
       first_seen,
       last_seen,
       subjects,
       first_adjudicated,
       resolved_at,
       regression_at,
       days_to_resolve,
       days_adjudicated_to_resolve,
       regression_days,
       regression_still_open,
       events
FROM finding_timeline
WHERE scope_id IN (SELECT value FROM json_each(:scope_ids))
ORDER BY scope_id, fingerprint;
