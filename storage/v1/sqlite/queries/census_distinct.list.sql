SELECT scope_id,
       ownership,
       report_kind,
       fingerprint,
       hardening,
       severity,
       open,
       occurrences,
       trees
FROM census_distinct
WHERE scope_id IN (SELECT value FROM json_each(:scope_ids))
ORDER BY scope_id, ownership, report_kind, fingerprint, hardening;
