INSERT INTO traust_storage_meta (
    id,
    contract_version,
    revision,
    applied_at
)
VALUES (
    1,
    :contract_version,
    :revision,
    :applied_at
)
ON CONFLICT (id) DO UPDATE SET
    contract_version = EXCLUDED.contract_version,
    revision = EXCLUDED.revision,
    applied_at = EXCLUDED.applied_at;
