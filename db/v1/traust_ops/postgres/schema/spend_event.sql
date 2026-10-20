-- What a run cost: one row per chargeable event, priced at the time.
--
-- Append-only. provider is a registered model provider; skill a registered
-- skill name - deployment data, checked at intake. run_order_id null =
-- unattributed. Retention: rolled up monthly after N months.
CREATE TABLE IF NOT EXISTS traust_ops.spend_event (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    run_order_id UUID REFERENCES traust_ops.run_order(id) ON DELETE RESTRICT,
    provider TEXT NOT NULL CHECK (provider <> ''),
    model TEXT NOT NULL CHECK (model <> ''),
    skill TEXT,
    tokens_in BIGINT NOT NULL,
    tokens_out BIGINT NOT NULL,
    cost_usd NUMERIC NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    CHECK (tokens_in >= 0 AND tokens_out >= 0 AND cost_usd >= 0)
);

-- Spend for an order (spend per scan, lane cost).
CREATE INDEX IF NOT EXISTS idx_ops_spend_event_run_order
    ON traust_ops.spend_event (run_order_id)
    WHERE run_order_id IS NOT NULL;

-- Spend in a window (spend dashboard, budget month-to-date).
CREATE INDEX IF NOT EXISTS idx_ops_spend_event_occurred
    ON traust_ops.spend_event (occurred_at);

DROP TRIGGER IF EXISTS ops_spend_event_reject_mutation ON traust_ops.spend_event;
CREATE TRIGGER ops_spend_event_reject_mutation
BEFORE UPDATE OR DELETE ON traust_ops.spend_event
FOR EACH ROW EXECUTE FUNCTION traust_ops.reject_mutation();

DROP TRIGGER IF EXISTS ops_spend_event_reject_truncate ON traust_ops.spend_event;
CREATE TRIGGER ops_spend_event_reject_truncate
BEFORE TRUNCATE ON traust_ops.spend_event
FOR EACH STATEMENT EXECUTE FUNCTION traust_ops.reject_mutation();
