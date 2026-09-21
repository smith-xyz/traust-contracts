SELECT scope_id,
       environment,
       tree,
       ownership,
       business_unit,
       product,
       claimed_severity,
       verdict,
       attempted,
       skip_reason,
       findings,
       subjects,
       distinct_claims
FROM traust_storage.validation_exposure
WHERE scope_id IN (
    SELECT jsonb_array_elements_text(%(scope_ids)s::jsonb)
)
ORDER BY scope_id, environment, tree, product, claimed_severity, verdict;
