-- Validation exposure: every claimed finding classified once by what
-- actually happened when it was attempted against a running system.
--
-- The census equivalent for the evidence lens. A finding CONFIRMED by
-- execution and a finding believed by inspection are different claims,
-- and this is the view that can tell them apart.
--
-- `verdict` stays uncollapsed and `attempted` is derived rather than
-- filtered, so a consumer can report "of what we tried, N% held up"
-- without restating the lane's own definition of an attempt. Folding
-- not_attempted into refuted would read as though the estate had
-- disproved the bulk of its findings; folding it away entirely would
-- hide most of the lane's work.
CREATE OR REPLACE VIEW traust_storage.validation_exposure WITH (security_barrier) AS
SELECT scope_id,
       tree,
       ownership,
       business_unit,
       product,
       claimed_severity,
       verdict,
       CASE WHEN verdict IN ('confirmed', 'refuted', 'inconclusive')
            THEN 1 ELSE 0 END AS attempted,
       skip_reason,
       COUNT(*) AS findings,
       COUNT(DISTINCT subject_id) AS subjects,
       COUNT(DISTINCT source_finding_id) AS distinct_claims
FROM traust_storage.validation_current
GROUP BY scope_id, tree, ownership, business_unit, product,
         claimed_severity, verdict,
         CASE WHEN verdict IN ('confirmed', 'refuted', 'inconclusive')
              THEN 1 ELSE 0 END,
         skip_reason;
