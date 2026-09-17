INSERT INTO traust_storage.triage_verdict (
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
    %(binding_id)s,
    %(artifact_digest)s,
    %(finding_id)s,
    %(source_finding_id)s,
    %(triage_completed)s,
    %(verdict)s,
    %(severity)s,
    %(vote_breakdown)s,
    %(rationale)s
)
ON CONFLICT (binding_id, finding_id) DO NOTHING;
