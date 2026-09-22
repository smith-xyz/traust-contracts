SELECT scope_id,
       technique,
       source,
       evidence_tier,
       occurrences,
       subjects
FROM attack_coverage
WHERE scope_id IN (SELECT value FROM json_each(:scope_ids))
ORDER BY scope_id, technique, evidence_tier DESC;
