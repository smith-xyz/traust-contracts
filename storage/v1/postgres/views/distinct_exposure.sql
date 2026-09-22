-- Distinct exposure (Lens 2): how many actual problems, not how many rows.
--
-- ONE ROW PER FINGERPRINT. Grouping by severity or business_unit as well
-- splits a single problem into several when it surfaces at different
-- severities across repos -- measured +219 against findings.db's
-- v_distinct_owned before this was corrected. severity and business_unit
-- are reported as EXAMPLES, which is what they are once collapsed.
--
-- Two filters carry the whole meaning and are easy to omit by accident:
--   ownership = 'owned'   upstream and external-bu engagements are Lens 1
--                         (work performed) only, never in risk numbers
--   is_branch_audit FALSE  a large share of audits re-audit the same code on
--                         a branch; counting them overstates coverage
CREATE OR REPLACE VIEW traust_storage.distinct_exposure AS
SELECT scope_id,
       fingerprint,
       COUNT(*) AS occurrences,
       -- Highest by RANK, not alphabetically: MAX over the text ranked
       -- 'medium' above 'critical'. Every Severity enum member is listed.
       CASE MAX(CASE severity WHEN 'critical' THEN 5 WHEN 'high' THEN 4 WHEN 'medium' THEN 3
                     WHEN 'low' THEN 2 WHEN 'informational' THEN 1 ELSE 0 END)
            WHEN 5 THEN 'critical' WHEN 4 THEN 'high' WHEN 3 THEN 'medium'
            WHEN 2 THEN 'low' WHEN 1 THEN 'informational' END AS severity_example,
       MIN(business_unit) AS business_unit_example,
       MIN(subject_id) AS first_subject
FROM traust_storage.current_finding
WHERE fingerprint IS NOT NULL
  AND ownership = 'owned'
  AND is_branch_audit = 0
  AND COALESCE(resolution, 'open') NOT IN ('resolved', 'risk_accepted')
  AND COALESCE(validity, 'confirmed') NOT IN ('false_positive', 'hardening')
GROUP BY scope_id, fingerprint;
