# Changelog

All notable changes to traust-contracts are documented here.

## [0.2.0]

- Add SQL-first `storage/v1`: authored SQLite/PostgreSQL schema, upserts and
  dashboard views, with relational projections for all 27 artifact schemas.
- Export `traust_contracts.storage.Store`, `IngestResult` and `IngestError`:
  exact-byte evidence, atomic projections, race-safe digest idempotency and
  revision preflight. SQLite uses stdlib; PostgreSQL uses the optional existing
  `postgres` extra.
- Ship authored SQL in wheels/sdists. Tests use focused inputs, not packaged
  conformance snapshots or generated fixtures. An explicit PostgreSQL test target
  loads `storage.yaml` from an explicitly selected test config home; CI integration remains pending.
- Add optional `storage.yaml` to the canonical config manifest, schema and typed
  context. Runtime callers and tests share the loader; no per-setting environment overrides.
- Use a live, scoped PostgreSQL dashboard instead of a materialized view.
  Storage revision 2 rejects mismatched databases rather than implying migrations.
- Keep evidence out of normal exception messages and tracebacks; explicit
  `IngestError.payload` access remains available for reject handling.
- Remove blanket SQL byte-pinning; SQL compatibility requires review, while the
  existing JSON Schema compatibility gate remains unchanged.

## [0.1.1]

## Changes

- **Timestamps are now enforced, not just declared.** New
  `traust_contracts.v1.timestamps` is the single definition of a valid ledger
  timestamp, shared by producers, models, and migrations: `is_rfc3339`
  (predicate), `to_rfc3339` (transform), and `IsoTimestamp` (model gate).
  Validation delegates to `rfc3339-validator` rather than
  `datetime.fromisoformat`, which is looser than RFC 3339 and accepts bare
  dates and naive datetimes the schemas forbid.

- **`jsonschema[format-nongpl]` is now a declared dependency.** The schemas
  have always declared `format: date-time`, but jsonschema only asserts that
  format when an assertor is installed — an unregistered format passes
  everything, so `FormatChecker().conforms('TrueT00:00:00+00:00', 'date-time')`
  returned `True`. The `format-nongpl` extra pulls MIT `rfc3339-validator`
  rather than GPL `strict-rfc3339`.

- **`LayerEvent.recorded_at`, `LayerEvent.occurred_at`, and
  `ReviewItem.recorded_at` are typed `IsoTimestamp`.** Previously bare `str`,
  so nothing checked them at either layer. Values are validated but never
  rewritten: `event_id` and the Merkle leaf are computed over the serialized
  event, so normalizing `+00:00` to `Z` (as `AwareDatetime` does) would
  re-root every layer and void every signature.

- **`ContractModel` sets `validate_assignment=True`.** Field constraints were
  only applied at construction, so `event.recorded_at = "banana"` was
  accepted afterwards. Applies to every contract model, not just timestamps.

### Breaking

Events whose `recorded_at` or `occurred_at` is not RFC 3339 now fail
validation on read as well as write. Corpora holding such values must be
migrated before adopting this release
(`traust.migrations.fix_event_timestamps` converts bare dates and drops
unrepairable optional values).

## [0.1.0]

Source of truth for JSON schemas and enums shared across the Traust
ecosystem, plus generated Python bindings and the configuration contract —
the authoritative manifest of what config exists and how it loads.
