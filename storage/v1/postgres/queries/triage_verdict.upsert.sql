INSERT INTO triage_verdict (
    layer_id,
    triage_completed,
    finding_id,
    source_finding_id,
    verdict,
    severity,
    vote_breakdown,
    rationale,
    artifact_digest
)
VALUES (
    %(layer_id)s,
    %(triage_completed)s,
    %(finding_id)s,
    %(source_finding_id)s,
    %(verdict)s,
    %(severity)s,
    %(vote_breakdown)s,
    %(rationale)s,
    %(artifact_digest)s
)
ON CONFLICT (layer_id, finding_id) DO UPDATE SET
    triage_completed = EXCLUDED.triage_completed,
    source_finding_id = EXCLUDED.source_finding_id,
    verdict = EXCLUDED.verdict,
    severity = EXCLUDED.severity,
    vote_breakdown = EXCLUDED.vote_breakdown,
    rationale = EXCLUDED.rationale,
    artifact_digest = EXCLUDED.artifact_digest;
