SELECT scope_id,
       technique,
       source,
       evidence_tier,
       occurrences,
       subjects
FROM traust_storage.attack_coverage
WHERE scope_id IN (
    SELECT jsonb_array_elements_text(%(scope_ids)s::jsonb)
)
ORDER BY scope_id, technique, evidence_tier DESC;
