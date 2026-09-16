INSERT INTO isolation_review (
    binding_id,
    artifact_digest,
    title,
    metadata,
    interfaces,
    gaps,
    posture,
    notes
) VALUES (
    %(binding_id)s,
    %(artifact_digest)s,
    %(title)s,
    %(metadata)s,
    %(interfaces)s,
    %(gaps)s,
    %(posture)s,
    %(notes)s
)
ON CONFLICT (binding_id) DO NOTHING;
