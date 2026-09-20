INSERT INTO traust_storage.validation_finding (
    binding_id,
    artifact_digest,
    source_id,
    source_finding_id,
    title,
    claimed_severity,
    surface,
    verdict,
    skip_reason,
    technique,
    observed_impact
)
VALUES (
    %(binding_id)s,
    %(artifact_digest)s,
    %(source_id)s,
    %(source_finding_id)s,
    %(title)s,
    %(claimed_severity)s,
    %(surface)s,
    %(verdict)s,
    %(skip_reason)s,
    %(technique)s,
    %(observed_impact)s
)
ON CONFLICT (binding_id, source_id) DO NOTHING;
