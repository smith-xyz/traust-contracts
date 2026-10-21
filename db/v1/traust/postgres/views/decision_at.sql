-- Each decision with the commit and line it judged: its assessment's
-- repository_ref, or the human's repository_ref. A bare commit has no name,
-- so its line reads with the commit-free fallback (current_resolution).
CREATE OR REPLACE VIEW traust.decision_at AS
SELECT d.*,
       rr.repository_id AS judged_repository_id,
       rr.name AS line
FROM traust.decision d
LEFT JOIN traust.assessment a ON a.id = d.assessment_id
LEFT JOIN traust.repository_ref rr ON rr.id = COALESCE(a.repository_ref_id, d.repository_ref_id);
