-- ATT&CK coverage: one row per technique per scope, with the STRONGEST
-- evidence the estate has for it.
--
-- Two sources, unioned and then ranked, because they are different claims:
--   modelled    a threat model names the technique (threat.attack_refs)
--   validated   a live-validation chain exercised it
--               (attack_chain.mitre_attack_refs)
--
-- `evidence_tier` orders them so a consumer sorts without restating the
-- rule, and the ordering is the whole point of the view:
--   3  chain CONFIRMED end to end -- reachable, demonstrated
--   2  chain attempted, not confirmed -- tried, did not land
--   1  modelled only -- nobody has attempted it
--
-- Collapsing those to "covered" is the failure this replaces. A technique
-- somebody wrote down and a technique somebody proved are not the same
-- coverage, and a Navigator layer coloured from the union of the two
-- overstates the estate's evidence everywhere it matters most.
--
-- Not filtered to confirmed. not_attempted dominates the validation lane,
-- so a coverage map showing only confirmations would describe a fraction
-- of the work and read as though the rest had been refuted.
CREATE OR REPLACE VIEW traust_storage.attack_coverage AS
SELECT scope_id,
       technique,
       source,
       evidence_tier,
       COUNT(*) AS occurrences,
       COUNT(DISTINCT subject_id) AS subjects
FROM (
    SELECT b.scope_id,
           ref.value AS technique,
           'validated' AS source,
           CASE WHEN c.verdict = 'confirmed' THEN 3 ELSE 2 END AS evidence_tier,
           b.subject_id
    FROM traust_storage.attack_chain c
    JOIN traust_storage.current_binding b
      ON b.binding_id = c.binding_id
    CROSS JOIN LATERAL jsonb_array_elements_text(c.mitre_attack_refs) AS ref(value)
    UNION ALL
    SELECT t.scope_id,
           ref.value AS technique,
           'modelled' AS source,
           1 AS evidence_tier,
           t.subject_id
    FROM traust_storage.threat_current t
    CROSS JOIN LATERAL jsonb_array_elements_text(t.attack_refs) AS ref(value)
) AS coverage
GROUP BY scope_id, technique, source, evidence_tier;
