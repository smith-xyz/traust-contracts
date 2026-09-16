INSERT INTO triage_verdict (
    binding_id,
    artifact_digest,
    finding_id,
    source_finding_id,
    triage_completed,
    verdict,
    severity,
    vote_breakdown,
    rationale
)
VALUES (
    :binding_id,
    :artifact_digest,
    :finding_id,
    :source_finding_id,
    :triage_completed,
    :verdict,
    :severity,
    :vote_breakdown,
    :rationale
)
ON CONFLICT (binding_id, finding_id) DO NOTHING;
