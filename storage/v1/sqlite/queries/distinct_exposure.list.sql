SELECT scope_id,
       ownership,
       business_unit,
       severity,
       fingerprint,
       occurrences,
       first_subject
FROM distinct_exposure
WHERE scope_id IN (SELECT value FROM json_each(:scope_ids))
ORDER BY scope_id, ownership, business_unit, severity, fingerprint;
