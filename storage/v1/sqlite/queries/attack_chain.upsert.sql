INSERT INTO attack_chain (
    binding_id,
    artifact_digest,
    chain_id,
    name,
    entry_point,
    terminal_asset,
    mitre_attack_refs,
    steps,
    verdict,
    narrative
)
VALUES (
    :binding_id,
    :artifact_digest,
    :chain_id,
    :name,
    :entry_point,
    :terminal_asset,
    :mitre_attack_refs,
    :steps,
    :verdict,
    :narrative
)
ON CONFLICT (binding_id, chain_id) DO NOTHING;
