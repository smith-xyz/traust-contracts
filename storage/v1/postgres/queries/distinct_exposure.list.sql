SELECT scope_id,
       ownership,
       business_unit,
       severity,
       fingerprint,
       occurrences,
       first_subject
FROM traust_storage.distinct_exposure
WHERE scope_id IN (
    SELECT jsonb_array_elements_text(%(scope_ids)s::jsonb)
)
ORDER BY scope_id, ownership, business_unit, severity, fingerprint;
