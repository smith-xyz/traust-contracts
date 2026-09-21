SELECT scope_id,
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
FROM validation_exposure
WHERE scope_id IN (SELECT value FROM json_each(:scope_ids))
ORDER BY scope_id, tree, product, claimed_severity, verdict;
