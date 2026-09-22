-- One ownership declaration per subject: the contract's answer to "which
-- corpus-registry do we believe?"
--
-- corpus-registry is an aggregate artifact restating the WHOLE population,
-- and it carries an `updated` timestamp, so every import produces new
-- content, a new digest and a new binding. subject_ownership is keyed on
-- (binding_id, subject_id), so those rows ACCUMULATE rather than replace.
--
-- Every view above this joins ownership on subject_id, so without this the
-- second import fans each finding out across N registry generations.
-- Measured on the live corpus: one re-import took current_finding from
-- DOUBLED both the finding count and the census population. It
-- stayed invisible because the store was always rebuilt from empty.
--
-- Most recently bound wins, with binding_id breaking ties, matching the
-- rule report_current already applies to restated reports.
CREATE OR REPLACE VIEW traust_storage.ownership_current AS
SELECT b.scope_id,
       b.binding_id,
       o.subject_id,
       o.tree,
       o.ownership,
       o.business_unit,
       o.label,
       o.product,
       o.repo_url,
       o.ref,
       o.ref_kind,
       o.is_branch_audit,
       o.report_kind
FROM traust_storage.subject_ownership o
JOIN traust_storage.artifact_binding b
  ON b.binding_id = o.binding_id
WHERE NOT EXISTS (
    SELECT 1
    FROM traust_storage.subject_ownership rival
    JOIN traust_storage.artifact_binding rival_binding
      ON rival_binding.binding_id = rival.binding_id
    WHERE rival.subject_id = o.subject_id
      AND (rival_binding.bound_at > b.bound_at
           OR (rival_binding.bound_at = b.bound_at
               AND rival_binding.binding_id > b.binding_id))
);
