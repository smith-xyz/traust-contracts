SELECT scope_id,
       ownership,
       report_kind,
       fingerprint,
       hardening,
       severity,
       open,
       occurrences,
       trees
FROM traust_storage.census_distinct
WHERE scope_id IN (
    SELECT jsonb_array_elements_text(%(scope_ids)s::jsonb)
)
ORDER BY scope_id, ownership, report_kind, fingerprint, hardening;
