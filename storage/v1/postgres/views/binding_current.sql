CREATE OR REPLACE VIEW traust_storage.current_binding AS
SELECT b.*
FROM traust_storage.artifact_binding b
WHERE NOT EXISTS (
    SELECT 1
    FROM traust_storage.artifact_binding successor
    WHERE successor.supersedes_binding_id = b.binding_id
      AND successor.scope_id = b.scope_id
);
