-- One unit of routed work: what traust ran, on what subject, in which lane.
--
-- Mutable table. Routed by the router (rule set) or injected as an event
-- (event_source set, contracts rescan-event-source) - never both; both null
-- = manual. state values (planned | queued | leased | succeeded | degraded
-- | refused | withheld | failed) come from contracts, to add - checked at
-- intake; withheld = dropped by the budget guard. reason is a reason code
-- (contracts, to add); detail goes to structured logs. lease_holder is set
-- exactly when state = leased. priority: lower = sooner; ties by created_at.
-- The run manifest (config digests, progress, budget verdict, degraded
-- keys) is artifact_id - per-run detail is not table rows.
CREATE TABLE IF NOT EXISTS traust_ops.run_order (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    run_batch_id UUID REFERENCES traust_ops.run_batch(id) ON DELETE RESTRICT,
    repository_id UUID REFERENCES traust.repository(id) ON DELETE RESTRICT,
    artifact_id UUID REFERENCES traust.artifact(id) ON DELETE RESTRICT,
    rule TEXT,
    event_source TEXT,
    lane TEXT NOT NULL CHECK (lane <> ''),
    state TEXT NOT NULL CHECK (state <> ''),
    priority INTEGER NOT NULL,
    reason TEXT,
    requested_by TEXT NOT NULL CHECK (requested_by <> ''),
    lease_holder TEXT,
    lease_expires_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT statement_timestamp(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT statement_timestamp(),
    PRIMARY KEY (id),
    CHECK (rule IS NULL OR event_source IS NULL),
    CHECK ((state = 'leased') = (lease_holder IS NOT NULL)),
    CHECK ((lease_holder IS NULL) = (lease_expires_at IS NULL)),
    CHECK (finished_at IS NULL OR started_at IS NULL OR finished_at >= started_at)
);

-- Claim the next queued order; weekly tranche selection.
CREATE INDEX IF NOT EXISTS idx_ops_run_order_claim
    ON traust_ops.run_order (state, priority, created_at);

-- Reap expired leases.
CREATE INDEX IF NOT EXISTS idx_ops_run_order_lease
    ON traust_ops.run_order (state, lease_expires_at);

-- A tranche's orders.
CREATE INDEX IF NOT EXISTS idx_ops_run_order_batch
    ON traust_ops.run_order (run_batch_id)
    WHERE run_batch_id IS NOT NULL;

-- A repository's planned / running orders (router dedupe).
CREATE INDEX IF NOT EXISTS idx_ops_run_order_repository_state
    ON traust_ops.run_order (repository_id, state)
    WHERE repository_id IS NOT NULL;

-- Cross-namespace link, closing the cycle: assessment.run_order_id ->
-- traust_ops.run_order. SQLite carries this FK inline (parent existence is
-- not checked at CREATE); Postgres cannot, because run_order references
-- storage tables back (repository, artifact) - the namespaces are mutually
-- recursive, and storage bootstraps first.
ALTER TABLE traust.assessment DROP CONSTRAINT IF EXISTS assessment_run_order_id_fkey;
ALTER TABLE traust.assessment
    ADD CONSTRAINT assessment_run_order_id_fkey
    FOREIGN KEY (run_order_id) REFERENCES traust_ops.run_order(id) ON DELETE RESTRICT;

DROP TRIGGER IF EXISTS run_order_touch ON traust_ops.run_order;
CREATE TRIGGER run_order_touch
BEFORE UPDATE ON traust_ops.run_order
FOR EACH ROW EXECUTE FUNCTION traust_ops.touch_updated_at();
