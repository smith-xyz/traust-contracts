-- Per finding: real? how bad? how proven? Each field is its latest non-null
-- answer - null means no answer, never "cleared", so a re-rating that sets
-- only severity keeps the earlier validity. Applies to every line of the
-- repository.
CREATE OR REPLACE VIEW traust.current_decision AS
SELECT f.finding_id,
       (SELECT d.validity
          FROM traust.decision d
         WHERE d.finding_id = f.finding_id AND d.validity IS NOT NULL
         ORDER BY d.occurred_at DESC, d.created_at DESC LIMIT 1) AS validity,
       (SELECT d.severity
          FROM traust.decision d
         WHERE d.finding_id = f.finding_id AND d.severity IS NOT NULL
         ORDER BY d.occurred_at DESC, d.created_at DESC LIMIT 1) AS severity,
       (SELECT d.evidence_grade
          FROM traust.decision d
         WHERE d.finding_id = f.finding_id AND d.evidence_grade IS NOT NULL
         ORDER BY d.occurred_at DESC, d.created_at DESC LIMIT 1) AS evidence_grade
FROM (SELECT DISTINCT finding_id FROM traust.decision) f;
