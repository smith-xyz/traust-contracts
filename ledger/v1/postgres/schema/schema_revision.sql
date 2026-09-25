CREATE TABLE traust_ledger.schema_revision (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    contract_version TEXT NOT NULL,
    revision INTEGER NOT NULL,
    applied_at TIMESTAMPTZ NOT NULL
);
