INSERT INTO traust_storage.subject_ownership (
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
    %(binding_id)s,
    %(artifact_digest)s,
    %(subject_id)s,
    %(tree)s,
    %(ownership)s,
    %(business_unit)s,
    %(label)s,
    %(product)s,
    %(repo_url)s,
    %(ref)s,
    %(ref_kind)s,
    %(is_branch_audit)s
)
ON CONFLICT (binding_id, subject_id) DO NOTHING;
