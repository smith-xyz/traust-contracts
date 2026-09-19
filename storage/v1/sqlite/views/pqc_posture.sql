-- Post-quantum readiness per subject, with its owner.
--
-- readiness_bucket is the headline: which repos can survive the migration
-- and which cannot. It is a projected COLUMN already; the flags that
-- decide urgency are one level down in JSON and are lifted here so a
-- consumer filters rather than parsing blobs.
--
-- `not-applicable` is a real bucket and NOT a gap: a repo with no
-- key-establishment surface has nothing to migrate. Folding it into
-- "not ready" would invent a backlog roughly the size of the ready one.
--
-- Ownership is LEFT JOINed. A PQC assessment exists for repos the corpus
-- registry may not declare, and such an assessment is still real -- it
-- simply has no denominator, and dropping it would hide it entirely.
CREATE VIEW IF NOT EXISTS pqc_posture AS
SELECT b.scope_id,
       b.subject_id,
       r.readiness_bucket,
       json_extract(r.flags, '$.has_2030_clock_items') AS has_2030_clock,
       json_extract(r.flags, '$.hndl_priority') AS hndl_priority,
       json_extract(r.flags, '$.runtime_verification_required')
           AS runtime_verification_required,
       json_extract(r.provenance_summary, '$.dominant') AS dominant_provenance,
       json_array_length(COALESCE(r.clock_items, '[]')) AS clock_items,
       owner.ownership,
       owner.business_unit,
       owner.tree,
       owner.is_branch_audit
FROM pqc_readiness r
JOIN current_binding b ON b.binding_id = r.binding_id
LEFT JOIN ownership_current owner ON owner.subject_id = b.subject_id;
