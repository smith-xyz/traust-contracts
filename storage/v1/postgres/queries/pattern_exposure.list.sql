SELECT scope_id,
       tree,
       ownership,
       business_unit,
       family,
       cwe,
       category,
       severity,
       effective_severity,
       exposure_class,
       occurrences,
       distinct_fingerprints,
       subjects
FROM traust_storage.pattern_exposure
WHERE scope_id IN (
    SELECT jsonb_array_elements_text(%(scope_ids)s::jsonb)
)
ORDER BY scope_id, tree, family, cwe, severity;
