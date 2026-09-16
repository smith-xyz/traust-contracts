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
    :binding_id,
    :artifact_digest,
    :finding_id,
    :target,
    :scanned_at,
    :title,
    :severity,
    :description,
    :category,
    :file,
    :line,
    :cwe,
    :recommendation,
    :confidence
)
ON CONFLICT (binding_id, finding_id) DO NOTHING;
