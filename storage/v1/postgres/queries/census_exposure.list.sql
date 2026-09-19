SELECT scope_id,
       tree,
       ownership,
       business_unit,
       is_branch_audit,
       family,
       severity,
       exposure_class,
       occurrences,
       distinct_fingerprints
FROM traust_storage.census_exposure
WHERE scope_id IN (
    SELECT jsonb_array_elements_text(%(scope_ids)s::jsonb)
)
ORDER BY scope_id, tree, ownership, business_unit, is_branch_audit,
         family, severity, exposure_class;
