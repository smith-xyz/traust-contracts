-- Distinct exposure for the CENSUS: one row per finding identity at HEAD,
-- under every ownership cut, hardening kept apart.
--
-- distinct_exposure answers one question (Lens 2, owned, open). The census
-- reports distinct vulnerabilities per ownership cut -- owned, upstream,
-- external-bu -- with the highest severity any occurrence carried, how many
-- are still open, and the hardening class as its own count. It had to
-- re-derive all of that from the reports because no view offered it.
--
-- One row per (ownership, report_kind, fingerprint, hardening). A
-- fingerprint that is a confirmed vulnerability in one repo and posture
-- debt in another appears once in each class, which is how the census
-- always counted it. False positives are not real and are dropped here;
-- branch re-audits are excluded because they restate HEAD.
--
-- `severity` is the highest across occurrences BY RANK; `open` is 1 when
-- any occurrence is not affirmatively closed.
CREATE OR REPLACE VIEW traust_storage.census_distinct AS
SELECT scope_id,
       ownership,
       report_kind,
       fingerprint,
       CASE WHEN COALESCE(validity, 'confirmed') = 'hardening' THEN 1 ELSE 0 END AS hardening,
       CASE MAX(CASE severity WHEN 'critical' THEN 5 WHEN 'high' THEN 4 WHEN 'medium' THEN 3
                     WHEN 'low' THEN 2 WHEN 'informational' THEN 1 ELSE 0 END)
            WHEN 5 THEN 'critical' WHEN 4 THEN 'high' WHEN 3 THEN 'medium'
            WHEN 2 THEN 'low' WHEN 1 THEN 'informational' END AS severity,
       MAX(CASE WHEN COALESCE(resolution, 'open') NOT IN ('resolved', 'risk_accepted')
                THEN 1 ELSE 0 END) AS open,
       COUNT(*) AS occurrences,
       COUNT(DISTINCT tree) AS trees
FROM traust_storage.current_finding
WHERE fingerprint IS NOT NULL
  AND is_branch_audit = 0
  AND COALESCE(validity, 'confirmed') <> 'false_positive'
GROUP BY scope_id, ownership, report_kind, fingerprint,
         CASE WHEN COALESCE(validity, 'confirmed') = 'hardening' THEN 1 ELSE 0 END;
