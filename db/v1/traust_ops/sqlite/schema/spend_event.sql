-- What a run cost: one row per chargeable event, priced at the time.
--
-- Append-only. provider is a registered model provider; skill a registered
-- skill name - deployment data, checked at intake. run_order_id null =
-- unattributed. Retention: rolled up monthly after N months.
CREATE TABLE IF NOT EXISTS ops_spend_event (
    id TEXT NOT NULL DEFAULT (uuid()),
    run_order_id TEXT REFERENCES ops_run_order(id) ON DELETE RESTRICT,
    provider TEXT NOT NULL CHECK (provider <> ''),
    model TEXT NOT NULL CHECK (model <> ''),
    skill TEXT,
    tokens_in INTEGER NOT NULL,
    tokens_out INTEGER NOT NULL,
    cost_usd NUMERIC NOT NULL,
    occurred_at TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    PRIMARY KEY (id),
    CHECK (tokens_in >= 0 AND tokens_out >= 0 AND cost_usd >= 0)
);

-- Spend for an order (spend per scan, lane cost).
CREATE INDEX IF NOT EXISTS idx_ops_spend_event_run_order
    ON ops_spend_event (run_order_id)
    WHERE run_order_id IS NOT NULL;

-- Spend in a window (spend dashboard, budget month-to-date).
CREATE INDEX IF NOT EXISTS idx_ops_spend_event_occurred
    ON ops_spend_event (occurred_at);

CREATE TRIGGER IF NOT EXISTS ops_spend_event_reject_update
BEFORE UPDATE ON ops_spend_event BEGIN
  SELECT RAISE(ABORT, 'ops_spend_event rows are append-only');
END;

CREATE TRIGGER IF NOT EXISTS ops_spend_event_reject_delete
BEFORE DELETE ON ops_spend_event BEGIN
  SELECT RAISE(ABORT, 'ops_spend_event rows are append-only');
END;
