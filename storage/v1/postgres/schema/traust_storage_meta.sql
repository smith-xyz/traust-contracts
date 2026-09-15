CREATE TABLE IF NOT EXISTS traust_storage_meta (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    contract_version TEXT NOT NULL,
    revision INTEGER NOT NULL,
    applied_at TIMESTAMPTZ NOT NULL
);
