-- One row per finding identity with its full clock: born, adjudicated,
-- closed, and how long each step took.
--
-- Joins the two halves of the time dimension -- first observation from the
-- reports, transitions from the ledger -- because neither alone is right:
-- reports know when a finding appeared but not what was decided about it,
-- and the ledger knows the decisions but only for the 60% that have any.
--
-- Durations use occurred_at, NEVER recorded_at. recorded_at is when the
-- ledger appended, and a bulk re-stamp moves it for thousands of events at
-- once -- computing MTTR on it would report the whole corpus as fixed on
-- the day of the re-stamp. The offset is normalised before the
-- subtraction, which matters: real events carry non-UTC offsets and a
-- naive string comparison is wrong by hours.
--
-- days_to_resolve is NULL while a finding is open. That is deliberate: a
-- mean over closed findings only is CENSORED and reads faster than reality,
-- so a consumer must see the open ones rather than have them silently
-- excluded by a zero.
CREATE VIEW IF NOT EXISTS finding_timeline AS
SELECT seen.scope_id,
       seen.fingerprint,
       seen.first_seen,
       seen.last_seen,
       seen.subjects,
       clock.first_adjudicated,
       clock.resolved_at,
       clock.regression_at,
       -- NULL when the clock is inconsistent rather than a negative
       -- number: a resolution dated BEFORE the first report we still hold
       -- means the report that first showed the finding is not in the
       -- corpus (superseded, or it failed validation), so the duration is
       -- unknown, not negative. Measured: 1 of 698 resolved findings.
       CASE WHEN clock.resolved_at IS NOT NULL
                 AND julianday(clock.resolved_at) >= julianday(seen.first_seen)
            THEN julianday(clock.resolved_at) - julianday(seen.first_seen)
       END AS days_to_resolve,
       CASE WHEN clock.resolved_at IS NOT NULL
                 AND julianday(clock.resolved_at) < julianday(seen.first_seen)
            THEN 1 ELSE 0 END AS clock_inconsistent,
       CASE WHEN clock.resolved_at IS NOT NULL AND clock.first_adjudicated IS NOT NULL
            THEN julianday(clock.resolved_at) - julianday(clock.first_adjudicated)
       END AS days_adjudicated_to_resolve,
       -- Only when the regression actually CLOSED. Running the clock to
       -- the last report date was wrong: a regression is often recorded
       -- after the last audit of that subject, which produced negative
       -- dwell on real data. An open regression's dwell is "as of when you
       -- ask", which belongs in the query alongside :as_of, not baked in
       -- here where every caller would inherit one arbitrary end date.
       CASE WHEN clock.regression_at IS NOT NULL
                 AND clock.resolved_after_regression IS NOT NULL
                 AND julianday(clock.resolved_after_regression)
                     >= julianday(clock.regression_at)
            THEN julianday(clock.resolved_after_regression)
                 - julianday(clock.regression_at)
       END AS regression_days,
       CASE WHEN clock.regression_at IS NOT NULL
                 AND clock.resolved_after_regression IS NULL
            THEN 1 ELSE 0 END AS regression_still_open,
       clock.events
FROM finding_first_seen seen
LEFT JOIN (
    SELECT b.scope_id,
           e.fingerprint,
           COUNT(*) AS events,
           MIN(e.occurred_at) AS first_adjudicated,
           MIN(CASE WHEN e.resolution = 'resolved' THEN e.occurred_at END) AS resolved_at,
           MIN(CASE WHEN e.resolution = 'regression_introduced' THEN e.occurred_at END)
               AS regression_at,
           MAX(CASE WHEN e.resolution = 'resolved' THEN e.occurred_at END)
               AS resolved_after_regression
    FROM layer_event e
    JOIN artifact_binding b ON b.binding_id = e.binding_id
    WHERE e.fingerprint IS NOT NULL AND e.occurred_at IS NOT NULL
    GROUP BY b.scope_id, e.fingerprint
) clock
  ON clock.scope_id = seen.scope_id AND clock.fingerprint = seen.fingerprint;
