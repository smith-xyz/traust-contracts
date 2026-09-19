SELECT scope_id,
       tree,
       ownership,
       business_unit,
       readiness_bucket,
       subjects,
       with_2030_clock,
       hndl_priority,
       clock_items
FROM pqc_readiness_rollup
WHERE scope_id IN (SELECT value FROM json_each(:scope_ids))
ORDER BY scope_id, tree, readiness_bucket;
