INSERT INTO traust_storage.risk_rating_methodology (
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
    %(binding_id)s,
    %(artifact_digest)s,
    %(methodology)s,
    %(methodology_version)s,
    %(source)s,
    %(documentation)s,
    %(schema)s,
    %(bands)s,
    %(bucket_thresholds)s,
    %(likelihood_factors)s,
    %(impact_factors)s,
    %(matrix)s,
    %(fallback)s,
    %(threat_intel_factor)s
)
ON CONFLICT (binding_id) DO NOTHING;
