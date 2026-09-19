SELECT scope_id,
       fingerprint,
       first_seen,
       last_seen,
       subjects,
       first_adjudicated,
       resolved_at,
       regression_at,
       days_to_resolve,
       clock_inconsistent,
       days_adjudicated_to_resolve,
       regression_days,
       regression_still_open,
       events
FROM traust_storage.finding_timeline
WHERE scope_id IN (
    SELECT jsonb_array_elements_text(%(scope_ids)s::jsonb)
)
ORDER BY scope_id, fingerprint;
