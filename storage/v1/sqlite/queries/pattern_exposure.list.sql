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
FROM pattern_exposure
WHERE scope_id IN (SELECT value FROM json_each(:scope_ids))
ORDER BY scope_id, tree, family, cwe, severity;
