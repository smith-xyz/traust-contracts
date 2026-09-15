INSERT INTO isolation_review (
    layer_id,
    project_id,
    artifact_digest,
    title,
    metadata,
    interfaces,
    gaps,
    posture,
    notes
) VALUES (
    %(layer_id)s,
    %(project_id)s,
    %(artifact_digest)s,
    %(title)s,
    %(metadata)s,
    %(interfaces)s,
    %(gaps)s,
    %(posture)s,
    %(notes)s
)
ON CONFLICT (layer_id) DO UPDATE SET
    project_id = excluded.project_id,
    artifact_digest = excluded.artifact_digest,
    title = excluded.title,
    metadata = excluded.metadata,
    interfaces = excluded.interfaces,
    gaps = excluded.gaps,
    posture = excluded.posture,
    notes = excluded.notes;
