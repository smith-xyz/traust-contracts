CREATE SCHEMA IF NOT EXISTS traust_ledger;

CREATE OR REPLACE FUNCTION traust_ledger.reject_authoritative_mutation()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'ledger authoritative history cannot be updated or deleted'
    USING ERRCODE = '55000';
END
$$;

CREATE OR REPLACE FUNCTION traust_ledger.validate_event_append()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE expected_seq integer;
BEGIN
  IF NEW.event_id IS NULL OR NEW.event_id = '' THEN
    RAISE EXCEPTION 'ledger event_id is required' USING ERRCODE = '23502';
  END IF;
  SELECT COALESCE(MAX(seq) + 1, 0) INTO expected_seq
    FROM traust_ledger.events WHERE layer_id = NEW.layer_id;
  IF NEW.seq <> expected_seq THEN
    RAISE EXCEPTION 'ledger event sequence %, expected % for layer %',
      NEW.seq, expected_seq, NEW.layer_id USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END
$$;
