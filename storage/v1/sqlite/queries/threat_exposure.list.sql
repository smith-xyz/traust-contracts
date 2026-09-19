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
FROM threat_exposure
WHERE scope_id IN (SELECT value FROM json_each(:scope_ids))
ORDER BY scope_id, tree, product, impact, likelihood, status;
