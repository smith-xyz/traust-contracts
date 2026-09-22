SELECT scope_id,
       tree,
       ownership,
       business_unit,
       subjects,
       branch_reaudits,
       with_report,
       report_kind
FROM census_population
WHERE scope_id IN (SELECT value FROM json_each(:scope_ids))
ORDER BY scope_id, tree, ownership, business_unit, report_kind;
