-- One report per subject: the contract's answer to "which restatement of
-- this repo's finding set do we count?"
--
-- A repo's findings are restated across artifacts -- a plain audit and a
-- disposition-aware findings-current report describe the SAME findings. Both
-- are legitimately current (neither supersedes the other; they are different
-- layers, not corrections), so counting report_finding directly counts every
-- finding once per restatement. The harness resolver has always applied this
-- preference in Python; storage/v1 had no concept of it.
--
-- Rank: a disposition-aware report outranks one that is not, matching the
-- resolver's LAYER PREFERENCE rule. disposition_summary is the discriminator
-- because it is already projected and, measured across the live corpus,
-- present on every findings-current report and no plain audit.
-- Among equals the most recently bound wins, with binding_id breaking ties so
-- the view is deterministic rather than arbitrary.
CREATE OR REPLACE VIEW traust_storage.report_current AS
SELECT b.scope_id,
       b.subject_id,
       b.run_id,
       b.layer_id,
       b.binding_id,
       r.artifact_digest,
       CASE WHEN r.disposition_summary IS NULL THEN 0 ELSE 1 END AS disposition_aware
FROM traust_storage.current_binding b
JOIN traust_storage.report r
  ON r.binding_id = b.binding_id
WHERE b.artifact_name = 'report'
  AND b.subject_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM traust_storage.current_binding rival
      JOIN traust_storage.report rival_report
        ON rival_report.binding_id = rival.binding_id
      WHERE rival.artifact_name = 'report'
        AND rival.subject_id = b.subject_id
        AND rival.scope_id = b.scope_id
        AND (
            (rival_report.disposition_summary IS NOT NULL
             AND r.disposition_summary IS NULL)
         OR ((rival_report.disposition_summary IS NULL)
              = (r.disposition_summary IS NULL)
             AND (rival.bound_at > b.bound_at
                  OR (rival.bound_at = b.bound_at
                      AND rival.binding_id > b.binding_id)))
        )
  );
