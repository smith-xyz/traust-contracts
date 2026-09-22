SELECT scope_id,
       boundary_key,
       boundary_id,
       subject_id,
       product,
       interface,
       kind,
       exposure,
       complexity,
       privilege,
       encryption,
       authentication,
       connectivity,
       hygiene,
       threat_ids,
       isolation_review_ref,
       weakness,
       open_threats,
       ownership,
       business_unit,
       tree,
       is_branch_audit
FROM traust_storage.boundary_current
WHERE scope_id IN (
    SELECT jsonb_array_elements_text(%(scope_ids)s::jsonb)
)
ORDER BY scope_id, boundary_key;
