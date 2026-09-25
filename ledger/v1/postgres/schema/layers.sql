CREATE TABLE traust_ledger.layers (
    layer_id VARCHAR NOT NULL,
    metadata_payload BYTEA NOT NULL,
    needs_review_payload BYTEA NOT NULL,
    extensions_payload BYTEA NOT NULL,
    root_keys_payload BYTEA NOT NULL,
    repository TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    merkle_root VARCHAR,
    merkle_epoch INTEGER,
    merkle_size INTEGER,
    merkle_root_signature TEXT,
    merkle_signing_method VARCHAR,
    merkle_signature_format INTEGER,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    PRIMARY KEY (layer_id)
);

DROP TRIGGER IF EXISTS layers_reject_delete ON traust_ledger.layers;
CREATE TRIGGER layers_reject_delete
BEFORE DELETE ON traust_ledger.layers
FOR EACH ROW EXECUTE FUNCTION traust_ledger.reject_authoritative_mutation();

DROP TRIGGER IF EXISTS layers_reject_truncate ON traust_ledger.layers;
CREATE TRIGGER layers_reject_truncate
BEFORE TRUNCATE ON traust_ledger.layers
FOR EACH STATEMENT EXECUTE FUNCTION traust_ledger.reject_authoritative_mutation();
