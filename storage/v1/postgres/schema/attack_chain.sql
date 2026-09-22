-- Per-chain projection of a live-validation run.
--
-- validation.attack_chains[] is the multi-step half of the evidence lens: a
-- path from an entry point to a terminal asset, with a verdict for the PATH
-- rather than for any one finding on it. It lived in a JSON column, so
-- ATT&CK coverage could only be derived by a script walking artifacts.
--
-- `mitre_attack_refs` is the join to the technique catalogue and the reason
-- this table exists: a chain confirmed end to end is the strongest evidence
-- the estate has that a technique is not merely modelled but reachable.
--
-- `verdict` carries the same five values as a validated finding, and for
-- the same reason -- not_attempted dominates, so collapsing to
-- confirmed/other would report the unexercised majority as refuted.
CREATE TABLE IF NOT EXISTS traust_storage.attack_chain (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    chain_id TEXT NOT NULL,
    name TEXT,
    entry_point TEXT,
    terminal_asset TEXT,
    mitre_attack_refs JSONB,
    steps JSONB,
    verdict TEXT,
    narrative TEXT,
    PRIMARY KEY (binding_id, chain_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES traust_storage.artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_attack_chain_verdict
    ON traust_storage.attack_chain (verdict);
