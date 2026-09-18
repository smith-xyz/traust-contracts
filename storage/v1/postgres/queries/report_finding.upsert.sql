INSERT INTO traust_storage.report_finding (
    binding_id,
    artifact_digest,
    finding_id,
    title,
    severity,
    fingerprint,
    validation_status,
    validity,
    resolution,
    assurance,
    last_updated,
    conflict,
    fp_overridden,
    fp_reassertion_blocked,
    refuted_awaiting_signoff,
    severity_override
)
VALUES (
    %(binding_id)s,
    %(artifact_digest)s,
    %(finding_id)s,
    %(title)s,
    %(severity)s,
    %(fingerprint)s,
    %(validation_status)s,
    %(validity)s,
    %(resolution)s,
    %(assurance)s,
    %(last_updated)s,
    %(conflict)s,
    %(fp_overridden)s,
    %(fp_reassertion_blocked)s,
    %(refuted_awaiting_signoff)s,
    %(severity_override)s
)
ON CONFLICT (binding_id, finding_id) DO NOTHING;
