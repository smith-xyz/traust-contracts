SELECT scope_id,
       tree,
       report_kind,
       branch_findings,
       head_confirmations,
       branch_only_distinct
FROM census_branch
WHERE scope_id IN (SELECT value FROM json_each(:scope_ids))
ORDER BY scope_id, tree, report_kind;
