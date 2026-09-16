INSERT INTO artifact_binding (
    binding_id,
    artifact_digest,
    artifact_name,
    scope_id,
    subject_id,
    run_id,
    layer_id,
    supersedes_binding_id,
    bound_at
)
VALUES (
    :binding_id,
    :artifact_digest,
    :artifact_name,
    :scope_id,
    :subject_id,
    :run_id,
    :layer_id,
    :supersedes_binding_id,
    :bound_at
)
ON CONFLICT (binding_id) DO NOTHING;
