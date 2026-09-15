INSERT INTO compliance_mapping (
    layer_id,
    project_id,
    artifact_digest,
    version,
    note,
    controls,
    checks
) VALUES (
    %(layer_id)s,
    %(project_id)s,
    %(artifact_digest)s,
    %(version)s,
    %(note)s,
    %(controls)s,
    %(checks)s
)
ON CONFLICT (layer_id) DO UPDATE SET
    project_id = excluded.project_id,
    artifact_digest = excluded.artifact_digest,
    version = excluded.version,
    note = excluded.note,
    controls = excluded.controls,
    checks = excluded.checks;
