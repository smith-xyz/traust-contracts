-- Per finding and line: fixed there? A line is a repository_ref name; line
-- null means the answer is not tied to a commit. A fix on one line does not
-- close another - read one line with its own answer first, then the
-- commit-free fallback.
CREATE VIEW IF NOT EXISTS current_resolution AS
SELECT s.finding_id,
       s.line,
       (SELECT d.resolution
          FROM decision_at d
         WHERE d.finding_id = s.finding_id
           AND d.line IS NOT DISTINCT FROM s.line
           AND d.resolution IS NOT NULL
         ORDER BY d.occurred_at DESC, d.created_at DESC LIMIT 1) AS resolution,
       (SELECT d.fixed_repository_ref_id
          FROM decision_at d
         WHERE d.finding_id = s.finding_id
           AND d.line IS NOT DISTINCT FROM s.line
           AND d.resolution IS NOT NULL
         ORDER BY d.occurred_at DESC, d.created_at DESC LIMIT 1) AS fixed_repository_ref_id
FROM (SELECT DISTINCT finding_id, line FROM decision_at WHERE resolution IS NOT NULL) s;
