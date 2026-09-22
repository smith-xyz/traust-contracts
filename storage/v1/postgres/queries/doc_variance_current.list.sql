SELECT scope_id,
       subject_id,
       repository,
       record_id,
       source_product_slug,
       source_version,
       source_guide,
       source_url,
       source_quote,
       claim,
       code_evidence,
       variance,
       verified_at,
       verified_against,
       disposition,
       disposition_note,
       finding_refs,
       threat_refs,
       ownership,
       business_unit,
       tree,
       product,
       is_branch_audit
FROM traust_storage.doc_variance_current
WHERE scope_id IN (
    SELECT jsonb_array_elements_text(%(scope_ids)s::jsonb)
)
ORDER BY scope_id, subject_id, record_id;
