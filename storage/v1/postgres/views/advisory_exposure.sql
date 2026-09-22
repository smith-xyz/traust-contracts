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
CREATE OR REPLACE VIEW traust_storage.advisory_exposure WITH (security_barrier) AS
SELECT b.scope_id,
       ia.metadata->>'cve' AS advisory,
       ia.metadata->>'ecosystem' AS ecosystem,
       ia.metadata->>'module' AS module,
       ia.metadata->>'fixed_version' AS fixed_version,
       ia.metadata->>'vulnerable_range' AS vulnerable_range,
       ia.metadata->>'generated_at' AS generated_at,
       ia.metadata->>'tiers_executed' AS tiers_executed,
       ia.metadata->>'vulnerable_symbols' AS vulnerable_symbols,
       ia.metadata->>'vulnerable_packages' AS vulnerable_packages,
       ia.metadata->>'advisory_sources' AS advisory_sources,
       ia.metadata->>'feature_description' AS feature_description,
       ia.metadata->>'harness_version' AS harness_version,
       ia.metadata->>'options' AS options,
       ia.metadata->>'portfolio_graph_db' AS portfolio_graph_db,
       ia.metadata->>'portfolio_graph_version' AS portfolio_graph_version,
       entry.value->>'repo' AS repo,
       entry.value->>'classification' AS classification,
       entry.value->>'version' AS version,
       entry.value->>'direct' AS direct,
       entry.value->>'products' AS products,
       entry.value->'evidence'->>'binary_linked_library' AS binary_linked_library,
       entry.value->'evidence'->>'binary_string_scan' AS binary_string_scan,
       entry.value->'evidence'->>'binary_symbol_scan' AS binary_symbol_scan,
       entry.value->'evidence'->>'evidence_level' AS evidence_level,
       entry.value->'evidence'->>'feature_pattern_matches' AS feature_pattern_matches,
       entry.value->'evidence'->>'govulncheck' AS govulncheck,
       entry.value->'evidence'->>'govulncheck_trace' AS govulncheck_trace,
       entry.value->'evidence'->>'l1_depends_on' AS l1_depends_on,
       entry.value->'evidence'->>'l1_version_in_range' AS l1_version_in_range,
       entry.value->'evidence'->>'l4_package_imported' AS l4_package_imported,
       entry.value->'evidence'->>'l4_packages_found' AS l4_packages_found,
       entry.value->'evidence'->>'manifest_scan' AS manifest_scan,
       entry.value->'evidence'->>'manifest_version' AS manifest_version,
       entry.value->'evidence'->>'needs_manual_trace' AS needs_manual_trace,
       entry.value->'evidence'->>'notes' AS notes,
       entry.value->'evidence'->>'sbom_scan' AS sbom_scan,
       entry.value->'evidence'->>'sbom_shipped_version' AS sbom_shipped_version,
       entry.value->'evidence'->>'source_import_scan' AS source_import_scan,
       entry.value->'evidence'->>'symbol_usage_scan' AS symbol_usage_scan
FROM traust_storage.impact_analysis ia
JOIN traust_storage.artifact_binding b
  ON b.binding_id = ia.binding_id
CROSS JOIN LATERAL jsonb_array_elements(ia.repos) AS entry(value)
WHERE b.artifact_name = 'impact-analysis'
  AND NOT EXISTS (
      SELECT 1
      FROM traust_storage.artifact_binding rival
      JOIN traust_storage.impact_analysis riv ON riv.binding_id = rival.binding_id
      WHERE rival.artifact_name = 'impact-analysis'
        AND rival.scope_id = b.scope_id
        AND riv.metadata->>'cve' = ia.metadata->>'cve'
        AND (rival.bound_at > b.bound_at
             OR (rival.bound_at = b.bound_at AND rival.binding_id > b.binding_id))
  );
