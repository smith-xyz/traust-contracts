-- Blast radius: which repositories one advisory reaches, and on what
-- evidence.
--
-- An impact analysis is scope-bound, not subject-bound: one advisory
-- assessed across many repositories at once. Fanned out here because the
-- question is always "which repos, how strongly", and that is a row per
-- repo, not a row per advisory.
--
-- Per-repo fields come from impact_repo, the fan-out table, never from
-- json_each over the blob at query time (README rule 3). The output
-- columns and their order are unchanged from the blob-reading version.
--
-- EVERY FIELD THE CONTRACT DECLARES IS CARRIED. The first cut exposed 14
-- of 40 and matched the legacy projection exactly on every classification
-- bucket -- because that projection dropped the same fields. Agreement
-- between two impoverished projections proves nothing; the SCHEMA is the
-- reference. tests/test_view_contract_coverage.py now enforces it.
--
-- `evidence_level` is the contract's own tier and the column to rank on:
-- symbol (govulncheck reachability) > binary (ELF) > manifest (lockfile
-- grep). The nineteen evidence flags beside it are how that tier was
-- reached, and they are the whole point of an impact analysis -- dropping
-- them leaves a verdict with no way to audit it.
--
-- Null in an evidence column means NOT ESTABLISHED, never "no". `direct`
-- separates a first-order dependency from a transitive one: the same
-- advisory is a different remediation job depending on which.
CREATE VIEW IF NOT EXISTS advisory_exposure AS
SELECT b.scope_id,
       json_extract(ia.metadata, '$.cve') AS advisory,
       json_extract(ia.metadata, '$.ecosystem') AS ecosystem,
       json_extract(ia.metadata, '$.module') AS module,
       json_extract(ia.metadata, '$.fixed_version') AS fixed_version,
       json_extract(ia.metadata, '$.vulnerable_range') AS vulnerable_range,
       json_extract(ia.metadata, '$.generated_at') AS generated_at,
       json_extract(ia.metadata, '$.tiers_executed') AS tiers_executed,
       json_extract(ia.metadata, '$.vulnerable_symbols') AS vulnerable_symbols,
       json_extract(ia.metadata, '$.vulnerable_packages') AS vulnerable_packages,
       json_extract(ia.metadata, '$.advisory_sources') AS advisory_sources,
       json_extract(ia.metadata, '$.feature_description') AS feature_description,
       json_extract(ia.metadata, '$.harness_version') AS harness_version,
       json_extract(ia.metadata, '$.options') AS options,
       json_extract(ia.metadata, '$.portfolio_graph_db') AS portfolio_graph_db,
       json_extract(ia.metadata, '$.portfolio_graph_version') AS portfolio_graph_version,
       ir.repo AS repo,
       ir.classification AS classification,
       ir.version AS version,
       ir.direct AS direct,
       ir.products AS products,
       ir.binary_linked_library AS binary_linked_library,
       ir.binary_string_scan AS binary_string_scan,
       ir.binary_symbol_scan AS binary_symbol_scan,
       ir.evidence_level AS evidence_level,
       ir.feature_pattern_matches AS feature_pattern_matches,
       ir.govulncheck AS govulncheck,
       ir.govulncheck_trace AS govulncheck_trace,
       ir.l1_depends_on AS l1_depends_on,
       ir.l1_version_in_range AS l1_version_in_range,
       ir.l4_package_imported AS l4_package_imported,
       ir.l4_packages_found AS l4_packages_found,
       ir.manifest_scan AS manifest_scan,
       ir.manifest_version AS manifest_version,
       ir.needs_manual_trace AS needs_manual_trace,
       ir.notes AS notes,
       ir.sbom_scan AS sbom_scan,
       ir.sbom_shipped_version AS sbom_shipped_version,
       ir.source_import_scan AS source_import_scan,
       ir.symbol_usage_scan AS symbol_usage_scan
FROM impact_analysis ia
JOIN artifact_binding b
  ON b.binding_id = ia.binding_id
JOIN impact_repo ir
  ON ir.binding_id = ia.binding_id
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
