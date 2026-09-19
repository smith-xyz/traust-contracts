SELECT scope_id,
       tree,
       ownership,
       business_unit,
       readiness_bucket,
       subjects,
       with_2030_clock,
       hndl_priority,
       clock_items
FROM traust_storage.pqc_readiness_rollup
WHERE scope_id IN (
    SELECT jsonb_array_elements_text(%(scope_ids)s::jsonb)
)
ORDER BY scope_id, tree, readiness_bucket;
