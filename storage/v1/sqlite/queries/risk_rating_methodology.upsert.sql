INSERT INTO risk_rating_methodology (
    binding_id,
    artifact_digest,
    methodology,
    methodology_version,
    source,
    documentation,
    schema,
    bands,
    bucket_thresholds,
    likelihood_factors,
    impact_factors,
    matrix,
    fallback,
    threat_intel_factor
) VALUES (
    :binding_id,
    :artifact_digest,
    :methodology,
    :methodology_version,
    :source,
    :documentation,
    :schema,
    :bands,
    :bucket_thresholds,
    :likelihood_factors,
    :impact_factors,
    :matrix,
    :fallback,
    :threat_intel_factor
)
ON CONFLICT (binding_id) DO NOTHING;
