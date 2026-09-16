INSERT INTO finding (
    binding_id,
    artifact_digest,
    finding_id,
    target,
    scanned_at,
    title,
    severity,
    description,
    category,
    file,
    line,
    cwe,
    recommendation,
    confidence
)
VALUES (
    %(binding_id)s,
    %(artifact_digest)s,
    %(finding_id)s,
    %(target)s,
    %(scanned_at)s,
    %(title)s,
    %(severity)s,
    %(description)s,
    %(category)s,
    %(file)s,
    %(line)s,
    %(cwe)s,
    %(recommendation)s,
    %(confidence)s
)
ON CONFLICT (binding_id, finding_id) DO NOTHING;
