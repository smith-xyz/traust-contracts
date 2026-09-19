-- Census exposure: every finding classified once, so no consumer
-- re-derives the disposition policy.
--
-- `distinct_exposure` answers one question (Lens 2 over owned HEAD).
-- The census answers several at once -- owned, upstream, external-bu,
-- cloud-config, branch re-audits, open against all -- and each is the same
-- data cut differently. Classifying here means a consumer FILTERS rather
-- than reimplements, which is where the numbers drifted before.
--
-- exposure_class is exhaustive and mutually exclusive:
--   false_positive  not real
--   hardening       real, posture debt, never folded into the headline
--   closed          affirmatively resolved or risk-accepted
--   open            everything else -- partial fixes and regressions included
CREATE OR REPLACE VIEW traust_storage.census_exposure AS
SELECT scope_id,
       tree,
       ownership,
       business_unit,
       is_branch_audit,
       family,
       severity,
       CASE
           WHEN COALESCE(validity, 'confirmed') = 'false_positive' THEN 'false_positive'
           WHEN COALESCE(validity, 'confirmed') = 'hardening' THEN 'hardening'
           WHEN COALESCE(resolution, 'open') IN ('resolved', 'risk_accepted') THEN 'closed'
           ELSE 'open'
       END AS exposure_class,
       COUNT(*) AS occurrences,
       COUNT(DISTINCT fingerprint) AS distinct_fingerprints
FROM traust_storage.current_finding
GROUP BY scope_id, tree, ownership, business_unit, is_branch_audit, family,
         severity,
         CASE
             WHEN COALESCE(validity, 'confirmed') = 'false_positive' THEN 'false_positive'
             WHEN COALESCE(validity, 'confirmed') = 'hardening' THEN 'hardening'
             WHEN COALESCE(resolution, 'open') IN ('resolved', 'risk_accepted') THEN 'closed'
             ELSE 'open'
         END;
