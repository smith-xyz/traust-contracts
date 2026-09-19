SELECT scope_id,
       fingerprint,
       occurrences,
       severity_example,
       business_unit_example,
       first_subject
FROM distinct_exposure
WHERE scope_id IN (SELECT value FROM json_each(:scope_ids))
ORDER BY scope_id, fingerprint;
