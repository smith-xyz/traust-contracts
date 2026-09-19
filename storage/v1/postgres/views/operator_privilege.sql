-- Operator privilege asks, with ownership, one row per current profile.
--
-- DECLARED state throughout: parsed from shipped manifests, never a live
-- cluster read. Every number here answers "what would this grant if
-- installed", and a consumer that reads it as runtime grant is wrong.
--
-- Bound through current_binding so a re-profiled operator is counted once.
-- The high-privilege flags are lifted to booleans because they are what the
-- least-privilege dashboard filters on; the full matched-rule lists stay in
-- the JSON column for the review itself.
CREATE OR REPLACE VIEW traust_storage.operator_privilege AS
SELECT b.scope_id,
       b.subject_id,
       b.run_id,
       p.repo,
       p.tier,
       p.workload_count,
       p.privileged_or_host_workloads,
       p.rbac_rule_count,
       p.distinct_rule_triples,
       p.distinct_cluster_triples,
       p.cluster_scoped_rules,
       p.wildcard_rules,
       p.no_scc_request_recorded,
       -- A key is present in rbac_flags ONLY when it matched, so presence
       -- IS the signal and an absent key means no match, not unknown.
       CASE WHEN jsonb_exists(p.rbac_flags, 'secrets_access') THEN 1 ELSE 0 END
           AS flag_secrets_access,
       CASE WHEN jsonb_exists(p.rbac_flags, 'nodes_access') THEN 1 ELSE 0 END
           AS flag_nodes_access,
       CASE WHEN jsonb_exists(p.rbac_flags, 'wildcard_verbs') THEN 1 ELSE 0 END
           AS flag_wildcard_verbs,
       CASE WHEN jsonb_exists(p.rbac_flags, 'wildcard_resources') THEN 1 ELSE 0 END
           AS flag_wildcard_resources,
       CASE WHEN jsonb_exists(p.rbac_flags, 'rbac_write') THEN 1 ELSE 0 END
           AS flag_rbac_write,
       CASE WHEN jsonb_exists(p.rbac_flags, 'pods_exec') THEN 1 ELSE 0 END
           AS flag_pods_exec,
       -- The three verbs that let a principal grant itself more than it
       -- holds. Highest-signal flag here.
       CASE WHEN jsonb_exists(p.rbac_flags, 'escalate_bind_impersonate') THEN 1 ELSE 0 END
           AS flag_escalate_bind_impersonate,
       owner.ownership,
       owner.business_unit,
       owner.tree,
       owner.is_branch_audit
FROM traust_storage.priv_profile p
JOIN traust_storage.current_binding b
  ON b.binding_id = p.binding_id
LEFT JOIN traust_storage.ownership_current owner
  ON owner.subject_id = b.subject_id;
