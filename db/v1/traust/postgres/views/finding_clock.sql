-- One row per finding: when it was first and last seen, first decided, and
-- closed. Seen = assessments that reported it (occurrence rows, superseded
-- or not); decided = first decision with a validity; closed = latest closing
-- decision, set only while finding_status says the finding is not open.
-- Trends and SLA build on this; SLA policy stays in config, not here.
CREATE OR REPLACE VIEW traust.finding_clock AS
SELECT fs.finding_id,
       fs.repository_id,
       seen.first_seen_at,
       seen.last_seen_at,
       COALESCE(seen.observations, 0) AS observations,
       (SELECT MIN(d.occurred_at)
          FROM traust.decision d
         WHERE d.finding_id = fs.finding_id AND d.validity IS NOT NULL) AS first_decided_at,
       CASE WHEN NOT fs.is_open THEN
           (SELECT MAX(d.occurred_at)
              FROM traust.decision d
             WHERE d.finding_id = fs.finding_id
               AND (d.validity IN ('false_positive', 'not_affected')
                    OR d.resolution IN ('resolved', 'risk_accepted')))
       END AS closed_at
FROM traust.finding_status fs
LEFT JOIN (SELECT o.finding_id,
                  MIN(a.occurred_at) AS first_seen_at,
                  MAX(a.occurred_at) AS last_seen_at,
                  COUNT(*) AS observations
             FROM traust.occurrence o
             JOIN traust.assessment a ON a.id = o.assessment_id
            GROUP BY o.finding_id) seen ON seen.finding_id = fs.finding_id;
