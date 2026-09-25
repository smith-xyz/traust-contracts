CREATE TABLE layers (
    layer_id VARCHAR NOT NULL,
    metadata_payload BLOB NOT NULL,
    needs_review_payload BLOB NOT NULL,
    extensions_payload BLOB NOT NULL,
    root_keys_payload BLOB NOT NULL,
    repository TEXT,
    created_at DATETIME,
    merkle_root VARCHAR,
    merkle_epoch INTEGER,
    merkle_size INTEGER,
    merkle_root_signature TEXT,
    merkle_signing_method VARCHAR,
    merkle_signature_format INTEGER,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (layer_id)
);
