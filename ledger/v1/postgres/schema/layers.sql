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
