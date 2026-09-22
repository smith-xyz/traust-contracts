SELECT scope_id,
       tree,
       ownership,
       business_unit,
       subjects,
       branch_reaudits,
       with_report,
       report_kind
FROM traust_storage.census_population
WHERE scope_id IN (
    SELECT jsonb_array_elements_text(%(scope_ids)s::jsonb)
)
ORDER BY scope_id, tree, ownership, business_unit, report_kind;
