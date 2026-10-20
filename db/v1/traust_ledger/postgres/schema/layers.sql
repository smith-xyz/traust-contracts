-- A ledger layer: one Merkle tree of decision events for one repository,
-- optionally one line (branch layers), signed at each root. line is the branch
-- name - a line is (repository_id, name) of repository_ref, derived, no table;
-- null = repository layer.
--
-- Mutable table: root, epoch and size advance as events append - the
-- traust-ledger library computes, the app stores. Merkle fields are null
-- until the first event is signed.
CREATE TABLE IF NOT EXISTS traust_ledger.layers (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    repository_id UUID NOT NULL REFERENCES traust.repository(id) ON DELETE RESTRICT,
    line TEXT CHECK (line <> ''),
    merkle_root TEXT,
    merkle_epoch INTEGER,
    merkle_size INTEGER,
    merkle_root_signature TEXT,
    merkle_signing_method TEXT NOT NULL CHECK (merkle_signing_method <> ''),
    merkle_signature_format INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id)
);

-- A repository's ledger layers (append / verify).
CREATE INDEX IF NOT EXISTS idx_ledger_layers_repository
    ON traust_ledger.layers (repository_id);

DROP TRIGGER IF EXISTS layers_touch ON traust_ledger.layers;
CREATE TRIGGER layers_touch
BEFORE UPDATE ON traust_ledger.layers
FOR EACH ROW EXECUTE FUNCTION traust_ledger.touch_updated_at();
