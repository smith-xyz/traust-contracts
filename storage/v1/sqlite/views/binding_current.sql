CREATE VIEW IF NOT EXISTS current_binding AS
SELECT b.*
FROM artifact_binding b
WHERE NOT EXISTS (
    SELECT 1
    FROM artifact_binding successor
    WHERE successor.supersedes_binding_id = b.binding_id
      AND successor.scope_id = b.scope_id
);
