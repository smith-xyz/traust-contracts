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
CREATE OR REPLACE VIEW traust_storage.pqc_posture AS
SELECT b.scope_id,
       b.subject_id,
       r.readiness_bucket,
       (r.flags->>'has_2030_clock_items')::boolean::int AS has_2030_clock,
       (r.flags->>'hndl_priority')::boolean::int AS hndl_priority,
       (r.flags->>'runtime_verification_required')::boolean::int
           AS runtime_verification_required,
       r.provenance_summary->>'dominant' AS dominant_provenance,
       jsonb_array_length(COALESCE(r.clock_items, '[]'::jsonb)) AS clock_items,
       owner.ownership,
       owner.business_unit,
       owner.tree,
       owner.is_branch_audit
FROM traust_storage.pqc_readiness r
JOIN traust_storage.current_binding b ON b.binding_id = r.binding_id
LEFT JOIN traust_storage.ownership_current owner ON owner.subject_id = b.subject_id;
