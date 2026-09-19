SELECT scope_id,
       tree,
       ownership,
       business_unit,
       product,
       impact,
       likelihood,
       status,
       evidenced,
       linddun,
       threats,
       subjects,
       top_score
FROM traust_storage.threat_exposure
WHERE scope_id IN (
    SELECT jsonb_array_elements_text(%(scope_ids)s::jsonb)
)
ORDER BY scope_id, tree, product, impact, likelihood, status;
