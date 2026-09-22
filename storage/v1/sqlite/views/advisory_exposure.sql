-- Blast radius: which repositories one advisory reaches, and on what
-- evidence.
--
-- An impact analysis is scope-bound, not subject-bound: one advisory
-- assessed across many repositories at once. Fanned out here because the
-- question is always "which repos, how strongly", and that is a row per
-- repo, not a row per advisory.
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
       json_extract(entry.value, '$.repo') AS repo,
       json_extract(entry.value, '$.classification') AS classification,
       json_extract(entry.value, '$.version') AS version,
       json_extract(entry.value, '$.direct') AS direct,
       json_extract(entry.value, '$.products') AS products,
       json_extract(entry.value, '$.evidence.binary_linked_library') AS binary_linked_library,
       json_extract(entry.value, '$.evidence.binary_string_scan') AS binary_string_scan,
       json_extract(entry.value, '$.evidence.binary_symbol_scan') AS binary_symbol_scan,
       json_extract(entry.value, '$.evidence.evidence_level') AS evidence_level,
       json_extract(entry.value, '$.evidence.feature_pattern_matches') AS feature_pattern_matches,
       json_extract(entry.value, '$.evidence.govulncheck') AS govulncheck,
       json_extract(entry.value, '$.evidence.govulncheck_trace') AS govulncheck_trace,
       json_extract(entry.value, '$.evidence.l1_depends_on') AS l1_depends_on,
       json_extract(entry.value, '$.evidence.l1_version_in_range') AS l1_version_in_range,
       json_extract(entry.value, '$.evidence.l4_package_imported') AS l4_package_imported,
       json_extract(entry.value, '$.evidence.l4_packages_found') AS l4_packages_found,
       json_extract(entry.value, '$.evidence.manifest_scan') AS manifest_scan,
       json_extract(entry.value, '$.evidence.manifest_version') AS manifest_version,
       json_extract(entry.value, '$.evidence.needs_manual_trace') AS needs_manual_trace,
       json_extract(entry.value, '$.evidence.notes') AS notes,
       json_extract(entry.value, '$.evidence.sbom_scan') AS sbom_scan,
       json_extract(entry.value, '$.evidence.sbom_shipped_version') AS sbom_shipped_version,
       json_extract(entry.value, '$.evidence.source_import_scan') AS source_import_scan,
       json_extract(entry.value, '$.evidence.symbol_usage_scan') AS symbol_usage_scan
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
