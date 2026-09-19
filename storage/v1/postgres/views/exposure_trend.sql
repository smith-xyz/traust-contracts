-- Findings opened and closed per month: the direction-of-travel view.
--
-- Counts each finding identity ONCE, in the month it was first observed
-- and (if it closed) the month it closed. A finding restated across twenty
-- re-audits contributes one open, not twenty -- which is the difference
-- between a trend and a measure of how often we re-scanned.
--
-- `net` is opened minus closed for that month. It is NOT the running
-- total: a cumulative figure depends on the window a consumer chose, so it
-- belongs in the query, not baked in here where two callers with different
-- windows would silently disagree.
CREATE OR REPLACE VIEW traust_storage.exposure_trend AS
SELECT scope_id, period, SUM(opened) AS opened, SUM(closed) AS closed,
       SUM(opened) - SUM(closed) AS net
FROM (
    SELECT scope_id, substring(first_seen from 1 for 7) AS period, 1 AS opened, 0 AS closed
    FROM traust_storage.finding_timeline WHERE first_seen IS NOT NULL
    UNION ALL
    SELECT scope_id, substring(resolved_at from 1 for 7) AS period, 0 AS opened, 1 AS closed
    FROM traust_storage.finding_timeline WHERE resolved_at IS NOT NULL
) periods
GROUP BY scope_id, period;
