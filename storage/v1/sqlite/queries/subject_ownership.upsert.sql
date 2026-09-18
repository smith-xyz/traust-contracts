INSERT INTO subject_ownership (
    binding_id,
    artifact_digest,
    subject_id,
    tree,
    ownership,
    business_unit,
    label,
    product,
    repo_url,
    ref,
    ref_kind,
    is_branch_audit
)
VALUES (
    :binding_id,
    :artifact_digest,
    :subject_id,
    :tree,
    :ownership,
    :business_unit,
    :label,
    :product,
    :repo_url,
    :ref,
    :ref_kind,
    :is_branch_audit
)
ON CONFLICT (binding_id, subject_id) DO NOTHING;
