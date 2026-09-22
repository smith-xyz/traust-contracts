-- Current doc-vs-code discrepancies, one row per record, with the
-- repository and owner of the subject they were found on.
--
-- One register per subject; a regenerated register supersedes its
-- predecessor by the rule every per-subject view applies -- most recently
-- bound wins, binding_id breaking ties. `disposition` is carried
-- UNCOLLAPSED: doc_corrected, code_fixed, accepted and superseded are
-- different outcomes, and 'open' is the only one that is exposure.
CREATE OR REPLACE VIEW traust_storage.doc_variance_current AS
SELECT b.scope_id,
       b.subject_id,
       dv.metadata->>'repository' AS repository,
       r.record_id,
       r.source_product_slug,
       r.source_version,
       r.source_guide,
       r.source_url,
       r.source_quote,
       r.claim,
       r.code_evidence,
       r.variance,
       r.verified_at,
       r.verified_against,
       r.disposition,
       r.disposition_note,
       r.finding_refs,
       r.threat_refs,
       owner.ownership,
       owner.business_unit,
       owner.tree,
       owner.product,
       owner.is_branch_audit
FROM traust_storage.doc_variance_record r
JOIN traust_storage.doc_variance dv
  ON dv.binding_id = r.binding_id
JOIN traust_storage.artifact_binding b
  ON b.binding_id = r.binding_id
LEFT JOIN traust_storage.ownership_current owner
  ON owner.subject_id = b.subject_id
WHERE b.artifact_name = 'doc-variance'
  AND NOT EXISTS (
      SELECT 1
      FROM traust_storage.artifact_binding rival
      WHERE rival.artifact_name = 'doc-variance'
        AND rival.scope_id = b.scope_id
        AND rival.subject_id = b.subject_id
        AND (rival.bound_at > b.bound_at
             OR (rival.bound_at = b.bound_at AND rival.binding_id > b.binding_id))
  );
