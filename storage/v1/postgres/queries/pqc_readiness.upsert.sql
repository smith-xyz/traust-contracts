INSERT INTO traust_storage.pqc_readiness (
    binding_id,
    artifact_digest,
    title,
    metadata,
    scores,
    flags,
    provenance_summary,
    clock_items,
    readiness_bucket,
    fips_interaction,
    runtime_evidence,
    server_side_caveats,
    notes,
    remediations
) VALUES (
    %(binding_id)s,
    %(artifact_digest)s,
    %(title)s,
    %(metadata)s,
    %(scores)s,
    %(flags)s,
    %(provenance_summary)s,
    %(clock_items)s,
    %(readiness_bucket)s,
    %(fips_interaction)s,
    %(runtime_evidence)s,
    %(server_side_caveats)s,
    %(notes)s,
    %(remediations)s
)
ON CONFLICT (binding_id) DO NOTHING;
