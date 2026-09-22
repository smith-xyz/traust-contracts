SELECT scope_id,
       tree,
       report_kind,
       branch_findings,
       head_confirmations,
       branch_only_distinct
FROM traust_storage.census_branch
WHERE scope_id IN (
    SELECT jsonb_array_elements_text(%(scope_ids)s::jsonb)
)
ORDER BY scope_id, tree, report_kind;
