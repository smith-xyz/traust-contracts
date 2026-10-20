-- A ledger layer: one Merkle tree of decision events for one repository,
-- optionally one line (branch layers), signed at each root. line is the branch
-- name - a line is (repository_id, name) of repository_ref, derived, no table;
-- null = repository layer.
--
-- Mutable table: root, epoch and size advance as events append - the
-- traust-ledger library computes, the app stores. Merkle fields are null
-- until the first event is signed.
CREATE TABLE IF NOT EXISTS ledger_layers (
    id TEXT NOT NULL DEFAULT (uuid()),
    repository_id TEXT NOT NULL REFERENCES repository(id) ON DELETE RESTRICT,
    line TEXT CHECK (line <> ''),
    merkle_root TEXT,
    merkle_epoch INTEGER,
    merkle_size INTEGER,
    merkle_root_signature TEXT,
    merkle_signing_method TEXT NOT NULL CHECK (merkle_signing_method <> ''),
    merkle_signature_format INTEGER,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    PRIMARY KEY (id)
);

-- A repository's ledger layers (append / verify).
CREATE INDEX IF NOT EXISTS idx_ledger_layers_repository
    ON ledger_layers (repository_id);

-- The database owns updated_at; the guard keeps it stable under recursive
-- triggers and respects a manually set value.
CREATE TRIGGER IF NOT EXISTS ledger_layers_touch
AFTER UPDATE ON ledger_layers FOR EACH ROW
WHEN NEW.updated_at IS OLD.updated_at BEGIN
  UPDATE ledger_layers SET updated_at = (strftime('%Y-%m-%dT%H:%M:%fZ','now')) WHERE id = NEW.id;
END;
