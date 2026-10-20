-- One row per finding: its current state on the repository's default line.
-- Validity, severity and evidence grade apply on every line
-- (current_decision); resolution is read on the default line, falling back to
-- the answer not tied to a commit (current_resolution). is_open is the one
-- definition of "open": not affirmatively closed - neither false_positive /
-- not_affected nor resolved / risk_accepted (classifier plan values).
-- Severity is the latest re-rating, else the latest reported severity.
-- Owners are not joined here (a repository can have several): join
-- ownership_current when a cut needs them.
CREATE OR REPLACE VIEW traust.finding_status AS
SELECT s.*,
       (s.validity IS NULL OR s.validity NOT IN ('false_positive', 'not_affected'))
       AND (s.resolution IS NULL OR s.resolution NOT IN ('resolved', 'risk_accepted')) AS is_open
FROM (
    SELECT f.id AS finding_id,
           f.repository_id,
           f.kind,
           f.title,
           cd.validity,
           cd.evidence_grade,
           COALESCE(cd.severity,
                    (SELECT o.severity
                       FROM traust.occurrence o
                       JOIN traust.assessment a ON a.id = o.assessment_id
                      WHERE o.finding_id = f.id
                      ORDER BY a.occurred_at DESC LIMIT 1)) AS severity,
           COALESCE((SELECT cr.resolution
                       FROM traust.current_resolution cr
                      WHERE cr.finding_id = f.id
                        AND cr.line = (SELECT rr.name
                                         FROM traust.repository_ref rr
                                        WHERE rr.repository_id = f.repository_id
                                          AND rr.is_default
                                        ORDER BY rr.created_at DESC LIMIT 1)),
                    (SELECT cr.resolution
                       FROM traust.current_resolution cr
                      WHERE cr.finding_id = f.id AND cr.line IS NULL)) AS resolution
    FROM traust.finding f
    LEFT JOIN traust.current_decision cd ON cd.finding_id = f.id
) s;
