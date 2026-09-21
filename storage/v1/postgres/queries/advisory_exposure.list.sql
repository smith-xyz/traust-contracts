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
FROM traust_storage.advisory_exposure
WHERE scope_id IN (
    SELECT jsonb_array_elements_text(%(scope_ids)s::jsonb)
)
ORDER BY scope_id, advisory, classification, repo;
