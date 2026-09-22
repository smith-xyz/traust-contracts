-- Junction: which threats a tenant boundary is tagged with.
--
-- tenant_boundaries[].threat_ids is an array per boundary. Counting the
-- open threats behind a boundary by matching an id against every entry of
-- that array at query time is what storage/v1/README.md rule 3 forbids, so
-- the array is fanned out here, one row per (boundary, threat), and
-- boundary_current joins it to the same model's `threat` rows.
CREATE TABLE IF NOT EXISTS boundary_threat (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    boundary_key TEXT NOT NULL,
    threat_id TEXT NOT NULL,
    PRIMARY KEY (binding_id, boundary_key, threat_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES artifact_binding(binding_id, artifact_digest)
);

CREATE INDEX IF NOT EXISTS idx_boundary_threat_threat
    ON boundary_threat (binding_id, threat_id);
