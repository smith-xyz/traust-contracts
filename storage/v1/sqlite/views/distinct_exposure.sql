-- Distinct exposure (Lens 2): how many actual problems, not how many rows.
--
-- Two filters carry the whole meaning and are easy to omit by accident:
--   ownership = 'owned'   upstream and external-bu engagements are Lens 1
--                         (work performed) only, never in risk numbers
--   is_branch_audit FALSE  a large share of audits re-audit the same code on
--                         a branch; counting them overstates coverage
CREATE VIEW IF NOT EXISTS distinct_exposure AS
SELECT scope_id, ownership, business_unit, severity, fingerprint,
       COUNT(*) AS occurrences,
       MIN(subject_id) AS first_subject
FROM current_finding
WHERE fingerprint IS NOT NULL
  AND ownership = 'owned'
  AND is_branch_audit = FALSE
  AND COALESCE(resolution, 'open') NOT IN ('resolved', 'risk_accepted')
  AND COALESCE(validity, 'confirmed') NOT IN ('false_positive', 'hardening')
GROUP BY scope_id, ownership, business_unit, severity, fingerprint;
