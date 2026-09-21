-- Blast radius: which repositories one advisory reaches, and on what
-- evidence.
--
-- An impact analysis is scope-bound, not subject-bound: one advisory
-- assessed across many repositories at once. Fanned out here because the
-- question is always "which repos, how strongly", and that is a row per
-- repo, not a row per advisory.
--
-- `evidence_level` is the CONTRACT'S OWN tier and the column to rank on:
-- symbol (govulncheck reachability) > binary (ELF) > manifest (lockfile
-- grep). Null on rows the lane could not tier, which is a third of them,
-- and null is not the bottom of the ordering -- it is "not established".
--
-- EVIDENCE STRENGTH IS CARRIED, NOT COLLAPSED. "the symbol is reachable
-- at a call site" and "the package is named in a manifest" are different
-- claims, and a rollup that blends them cannot be acted on -- it reads as
-- though every hit needed the same urgency. `classification` is the
-- lane's own verdict; the l1_* evidence flags are what it concluded from.
--
-- `direct` separates a first-order dependency from one pulled in
-- transitively: the same advisory is a different remediation job
-- depending on which it is.
CREATE VIEW IF NOT EXISTS advisory_exposure AS
SELECT b.scope_id,
       json_extract(ia.metadata, '$.cve') AS advisory,
       json_extract(ia.metadata, '$.ecosystem') AS ecosystem,
       json_extract(ia.metadata, '$.module') AS module,
       json_extract(ia.metadata, '$.fixed_version') AS fixed_version,
       json_extract(entry.value, '$.repo') AS repo,
       json_extract(entry.value, '$.classification') AS classification,
       json_extract(entry.value, '$.version') AS version,
       json_extract(entry.value, '$.direct') AS direct,
       json_extract(entry.value, '$.evidence.evidence_level') AS evidence_level,
       json_extract(entry.value, '$.evidence.l1_depends_on') AS depends_on,
       json_extract(entry.value, '$.evidence.l1_version_in_range') AS version_in_range,
       json_extract(entry.value, '$.evidence.needs_manual_trace') AS needs_manual_trace,
       json_extract(entry.value, '$.products') AS products
FROM impact_analysis ia
JOIN artifact_binding b
  ON b.binding_id = ia.binding_id
JOIN json_each(ia.repos) entry
WHERE b.artifact_name = 'impact-analysis'
  AND NOT EXISTS (
      SELECT 1
      FROM artifact_binding rival
      JOIN impact_analysis riv ON riv.binding_id = rival.binding_id
      WHERE rival.artifact_name = 'impact-analysis'
        AND rival.scope_id = b.scope_id
        AND json_extract(riv.metadata, '$.cve') = json_extract(ia.metadata, '$.cve')
        AND (rival.bound_at > b.bound_at
             OR (rival.bound_at = b.bound_at AND rival.binding_id > b.binding_id))
  );
