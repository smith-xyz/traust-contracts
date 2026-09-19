-- Operator privilege asks, with ownership, one row per current profile.
--
-- DECLARED state throughout: parsed from shipped manifests, never a live
-- cluster read. Every number here answers "what would this grant if
-- installed", and a consumer that reads it as a runtime grant is wrong.
--
-- The counts are EXTRACTED from the summary blob rather than stored twice.
-- The projection holds one column per root property of the artifact, which
-- is the invariant every one-row projection here keeps; lifting derived
-- numbers into their own columns would put two copies of each in the
-- database, and two copies of one number is how they drift.
--
-- The high-privilege flags become booleans because that is what a
-- least-privilege dashboard filters on. A key is present in rbac_flags
-- ONLY when it matched, so presence IS the signal and an absent key means
-- no match rather than unknown -- hence 0, never NULL, or a filter silently
-- drops the row.
CREATE OR REPLACE VIEW traust_storage.operator_privilege AS
SELECT b.scope_id,
       b.subject_id,
       b.run_id,
       p.repo,
       p.tier,
       (p.summary->>'workloads')::int AS workload_count,
       (p.summary->>'privileged_or_host_workloads')::int
           AS privileged_or_host_workloads,
       (p.summary->>'rbac_rules')::int AS rbac_rule_count,
       (p.summary->>'distinct_rule_triples')::int AS distinct_rule_triples,
       (p.summary->>'distinct_cluster_triples')::int AS distinct_cluster_triples,
       (p.summary->>'cluster_scoped_rules')::int AS cluster_scoped_rules,
       (p.summary->>'wildcard_rules')::int AS wildcard_rules,
       (p.summary->>'no_scc_request_recorded')::boolean::int AS no_scc_request_recorded,
       CASE WHEN NOT jsonb_exists(p.rbac_flags, 'secrets_access') THEN 0 ELSE 1 END
           AS flag_secrets_access,
       CASE WHEN NOT jsonb_exists(p.rbac_flags, 'nodes_access') THEN 0 ELSE 1 END
           AS flag_nodes_access,
       CASE WHEN NOT jsonb_exists(p.rbac_flags, 'wildcard_verbs') THEN 0 ELSE 1 END
           AS flag_wildcard_verbs,
       CASE WHEN NOT jsonb_exists(p.rbac_flags, 'wildcard_resources') THEN 0 ELSE 1 END
           AS flag_wildcard_resources,
       CASE WHEN NOT jsonb_exists(p.rbac_flags, 'rbac_write') THEN 0 ELSE 1 END
           AS flag_rbac_write,
       CASE WHEN NOT jsonb_exists(p.rbac_flags, 'pods_exec') THEN 0 ELSE 1 END
           AS flag_pods_exec,
       -- The three verbs that let a principal grant itself more than it
       -- holds. Highest-signal flag here.
       CASE WHEN NOT jsonb_exists(p.rbac_flags, 'escalate_bind_impersonate')
            THEN 0 ELSE 1 END AS flag_escalate_bind_impersonate,
       owner.ownership,
       owner.business_unit,
       owner.tree,
       owner.is_branch_audit
FROM traust_storage.priv_profile p
JOIN traust_storage.current_binding b
  ON b.binding_id = p.binding_id
LEFT JOIN traust_storage.ownership_current owner
  ON owner.subject_id = b.subject_id;
