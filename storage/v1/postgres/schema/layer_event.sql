-- Per-event projection of a ledger layer: the TIME DIMENSION.
--
-- layer.events is an append-only, chronologically ordered disposition
-- stream -- every validity and resolution change a finding ever went
-- through, each one dated. It was ingested and then discarded:
-- layer_metadata kept only repo, created_at and the merkle root, so
-- storage/v1 could answer "what is open now" and nothing at all about
-- "what was open in July", "how long did this take to fix", or "how long
-- was that regression live".
--
-- Same relationship report_finding has to report.findings: the layer blob
-- stays authoritative and this is a queryable index over it. Measured on
-- the live corpus, ~64,000 events across 7,309 layers.
--
-- This is why trending needs no scheduled snapshot. An append-only log of
-- dated transitions IS a time series; a snapshot is that log folded at one
-- moment. Keep the log and any past date stays reconstructable; keep only
-- snapshots and everything before the first run is gone forever, from a
-- second source of truth that can drift from the events.
CREATE TABLE IF NOT EXISTS traust_storage.layer_event (
    binding_id TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    event_id TEXT NOT NULL,
    finding_ref TEXT NOT NULL,
    -- Identity across re-audits. finding_ref is scan-scoped, so a trend
    -- keyed on it alone breaks the moment a report renumbers.
    fingerprint TEXT,
    fingerprint_algo TEXT,
    -- recorded_at is when the ledger appended; occurred_at is when the
    -- determination actually happened. Durations MUST use occurred_at --
    -- a bulk re-stamp moves recorded_at for thousands of events at once
    -- and would report every one of them as fixed that day.
    recorded_at TEXT NOT NULL,
    occurred_at TEXT,
    source_type TEXT,
    source_ref TEXT,
    actor_kind TEXT,
    validity TEXT,
    resolution TEXT,
    evidence_grade TEXT,
    auto_accept_tier INTEGER,
    PRIMARY KEY (binding_id, event_id),
    FOREIGN KEY (binding_id, artifact_digest)
        REFERENCES traust_storage.artifact_binding(binding_id, artifact_digest)
);

-- The trend fold walks the stream in time order per finding.
CREATE INDEX IF NOT EXISTS idx_layer_event_clock
    ON traust_storage.layer_event (fingerprint, occurred_at);

CREATE INDEX IF NOT EXISTS idx_layer_event_resolution
    ON traust_storage.layer_event (resolution, occurred_at);
