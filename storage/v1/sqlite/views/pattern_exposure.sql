-- Recurring weakness patterns: one row per CWE per cut, fanned out of the
-- finding's cwes[] rather than counted per finding.
--
-- The dashboard this replaces grouped by a PRIMARY cwe -- the first entry of
-- the list -- because that is what a Python loop makes easy. A finding
-- declaring CWE-78 and CWE-88 is an instance of both patterns, and reporting
-- it only against the first understates the second. Fanning the array out
-- means one finding can appear under several CWEs, so `occurrences` here sums
-- to more than the finding count. That is the correct reading of "how many
-- findings involve this weakness" and the reason the column is not named
-- `findings`.
--
-- json_each over cwes is a small flat array of strings, not the quadratic
-- join storage/v1/README.md rule 3 warns about: that rule is about matching
-- an id against every entry of the same array, which this does not do.
--
-- Classified, never filtered -- the census convention. `family` separates
-- code findings from policy findings, `exposure_class` carries disposition
-- exactly as census_exposure defines it, and a consumer wanting only open
-- source-code patterns filters on both rather than restating the policy.
CREATE VIEW IF NOT EXISTS pattern_exposure AS
SELECT f.scope_id,
       f.tree,
       f.ownership,
       f.business_unit,
       f.family,
       cwe.value AS cwe,
       f.category,
       f.severity,
       f.effective_severity,
       CASE
           WHEN COALESCE(f.validity, 'confirmed') = 'false_positive' THEN 'false_positive'
           WHEN COALESCE(f.validity, 'confirmed') = 'hardening' THEN 'hardening'
           WHEN COALESCE(f.resolution, 'open') IN ('resolved', 'risk_accepted') THEN 'closed'
           ELSE 'open'
       END AS exposure_class,
       COUNT(*) AS occurrences,
       COUNT(DISTINCT f.fingerprint) AS distinct_fingerprints,
       COUNT(DISTINCT f.subject_id) AS subjects
FROM current_finding f
JOIN json_each(f.cwes) cwe
GROUP BY f.scope_id, f.tree, f.ownership, f.business_unit, f.family,
         cwe.value, f.category, f.severity, f.effective_severity,
         CASE
             WHEN COALESCE(f.validity, 'confirmed') = 'false_positive' THEN 'false_positive'
             WHEN COALESCE(f.validity, 'confirmed') = 'hardening' THEN 'hardening'
             WHEN COALESCE(f.resolution, 'open') IN ('resolved', 'risk_accepted') THEN 'closed'
             ELSE 'open'
         END;
