INSERT INTO pqc_readiness (
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
    :binding_id,
    :artifact_digest,
    :title,
    :metadata,
    :scores,
    :flags,
    :provenance_summary,
    :clock_items,
    :readiness_bucket,
    :fips_interaction,
    :runtime_evidence,
    :server_side_caveats,
    :notes,
    :remediations
)
ON CONFLICT (binding_id) DO NOTHING;
