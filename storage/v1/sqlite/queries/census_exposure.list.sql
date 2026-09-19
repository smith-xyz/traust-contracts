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
FROM census_exposure
WHERE scope_id IN (SELECT value FROM json_each(:scope_ids))
ORDER BY scope_id, tree, ownership, business_unit, is_branch_audit,
         family, severity, exposure_class;
