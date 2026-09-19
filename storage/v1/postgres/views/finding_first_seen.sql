-- When each finding was FIRST observed, across every report that carried it.
--
-- The birth half of the time dimension. The ledger's earliest event is a
-- triage verdict, which is when a finding was first ADJUDICATED, not when
-- it was first seen -- and only 60% of findings have any event at all
-- (measured: 48,019 of 79,998). Using the ledger alone as the clock start
-- therefore undercounts the population and overstates how fast things move.
--
-- report_finding keeps a row per report BINDING, including superseded
-- ones, so the earliest report carrying a fingerprint is still on record
-- even after re-audits. That is the true first observation, and it covers
-- every finding because report.metadata.date is required.
CREATE OR REPLACE VIEW traust_storage.finding_first_seen AS
SELECT b.scope_id,
       f.fingerprint,
       MIN((r.metadata->>'date')) AS first_seen,
       MAX((r.metadata->>'date')) AS last_seen,
       COUNT(DISTINCT b.subject_id) AS subjects
FROM traust_storage.report_finding f
JOIN traust_storage.artifact_binding b ON b.binding_id = f.binding_id
JOIN traust_storage.report r ON r.binding_id = f.binding_id
WHERE f.fingerprint IS NOT NULL
GROUP BY b.scope_id, f.fingerprint;
