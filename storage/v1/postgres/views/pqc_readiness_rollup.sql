-- PQC readiness aggregated: the shape a portfolio dashboard renders.
--
-- Counts SUBJECTS, not assessments. A repo re-assessed five times is one
-- repo in a readiness bucket, and counting assessments would inflate the
-- portfolio by however often it was re-scanned.
CREATE OR REPLACE VIEW traust_storage.pqc_readiness_rollup AS
SELECT scope_id,
       tree,
       ownership,
       business_unit,
       readiness_bucket,
       COUNT(DISTINCT subject_id) AS subjects,
       SUM(CASE WHEN has_2030_clock = 1 THEN 1 ELSE 0 END) AS with_2030_clock,
       SUM(CASE WHEN hndl_priority = 1 THEN 1 ELSE 0 END) AS hndl_priority,
       SUM(clock_items) AS clock_items
FROM traust_storage.pqc_posture
GROUP BY scope_id, tree, ownership, business_unit, readiness_bucket;
