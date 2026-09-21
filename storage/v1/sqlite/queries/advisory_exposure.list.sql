SELECT scope_id,
       advisory,
       ecosystem,
       module,
       fixed_version,
       repo,
       classification,
       version,
       direct,
       evidence_level,
       depends_on,
       version_in_range,
       needs_manual_trace,
       products
FROM advisory_exposure
WHERE scope_id IN (SELECT value FROM json_each(:scope_ids))
ORDER BY scope_id, advisory, classification, repo;
