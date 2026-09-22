INSERT INTO traust_storage.attack_chain (
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
    %(binding_id)s,
    %(artifact_digest)s,
    %(chain_id)s,
    %(name)s,
    %(entry_point)s,
    %(terminal_asset)s,
    %(mitre_attack_refs)s,
    %(steps)s,
    %(verdict)s,
    %(narrative)s
)
ON CONFLICT (binding_id, chain_id) DO NOTHING;
