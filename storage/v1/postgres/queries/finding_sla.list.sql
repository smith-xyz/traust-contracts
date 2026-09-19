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
FROM traust_storage.finding_sla
WHERE scope_id IN (
    SELECT jsonb_array_elements_text(%(scope_ids)s::jsonb)
)
ORDER BY scope_id, age_days DESC;
