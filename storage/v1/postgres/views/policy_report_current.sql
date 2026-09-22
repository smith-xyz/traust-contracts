-- One policy report per subject: report_current for the cloud-config
-- family.
--
-- A cloud-config subject carries a plain audit and, once dispositioned, a
-- findings-current restatement of the SAME findings. Both project into
-- cloud_config_finding, so counting that table directly counts every
-- policy finding once per restatement -- the exact double count
-- report_current removes for code findings. The disposition-aware
-- artifact outranks the plain audit; among equals the most recently
-- bound wins, binding_id breaking ties.
CREATE OR REPLACE VIEW traust_storage.policy_report_current AS
SELECT b.scope_id,
       b.subject_id,
       b.run_id,
       b.binding_id,
       CASE WHEN b.artifact_name = 'cloud-config-findings-current' THEN 1 ELSE 0 END
           AS disposition_aware
FROM traust_storage.current_binding b
WHERE b.artifact_name IN ('cloud-config-audit', 'cloud-config-findings-current')
  AND b.subject_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM traust_storage.current_binding rival
      WHERE rival.artifact_name IN ('cloud-config-audit', 'cloud-config-findings-current')
        AND rival.subject_id = b.subject_id
        AND rival.scope_id = b.scope_id
        AND (
            (rival.artifact_name = 'cloud-config-findings-current'
             AND b.artifact_name = 'cloud-config-audit')
         OR (rival.artifact_name = b.artifact_name
             AND (rival.bound_at > b.bound_at
                  OR (rival.bound_at = b.bound_at
                      AND rival.binding_id > b.binding_id)))
        )
  );
