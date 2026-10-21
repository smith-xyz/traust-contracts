-- A source repository, once, however many products include it.
--
-- Mutable table. One natural key (url, exact string - not canonicalized).
-- upstream_id self-references the repository this one forks: null = no
-- upstream recorded. Not indexed on purpose: rare single-row lookups.
CREATE TABLE IF NOT EXISTS repository (
    id TEXT NOT NULL DEFAULT (uuid()),
    upstream_id TEXT REFERENCES repository(id) ON DELETE RESTRICT,
    url TEXT NOT NULL CHECK (url <> ''),
    public BOOLEAN NOT NULL CHECK (public IN (0, 1)),
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    PRIMARY KEY (id),
    UNIQUE (url)
);

-- The database owns updated_at; the guard keeps it stable under recursive
-- triggers and respects a manually set value.
CREATE TRIGGER IF NOT EXISTS repository_touch
AFTER UPDATE ON repository FOR EACH ROW
WHEN NEW.updated_at IS OLD.updated_at BEGIN
  UPDATE repository SET updated_at = (strftime('%Y-%m-%dT%H:%M:%fZ','now')) WHERE id = NEW.id;
END;
