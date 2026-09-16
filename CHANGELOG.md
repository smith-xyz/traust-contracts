# Changelog

All notable changes to traust-contracts are documented here.

## [0.3.0]

## Changes

- **Typed base-versus-patch patch evidence.** New optional `evidence[]` on
  remediation reports, with `$defs/patch_evidence` and the
  `patch_evidence_kind` enum (`regression`, `mutation`, `property`,
  `scanner_differential`, `exploit`). Each item records what was observed on
  the unpatched and the patched revision.

  The load-bearing rule is a conditional: an item may claim
  `outcome: proves` or `fails_to_prove` **only if both observations are
  present**, so a check that never ran cannot be filed as evidence. Items that
  were not attempted carry their reason inline (`not_attempted: <reason>`),
  matching the existing `deterministic_steps` shape.

  Additive and optional — `evidence` is absent from `required`, so every
  existing remediation report stays valid. `revalidation` is untouched and
  remains the live-validation channel: its `method` values and the new
  evidence kinds are disjoint, so a mutation verdict can never be mistaken for
  a live-validation verdict. What each kind may legitimately conclude is
  bounded by the per-path evidence ceilings in the harness's
  `docs/disposition-ledger.md` section 8a.

- **The compatibility gate no longer reads a new optional sub-object as a
  breaking change.** `test_no_breaking_changes_vs_previous_tag` flagged any
  newly added conditional `required`, including one inside a brand-new `$def`
  that no artifact of the previous tag could reach. It now exempts a
  conditional only when EVERY reference chain from the schema root to its
  containing `$def` crosses a property absent from the old schema — under
  `additionalProperties: false`, an old artifact cannot carry such a property,
  so the rule cannot invalidate it. Four tests pin the limits of the
  exemption: a conditional tightened on an existing `$def`, a new `$def`
  swapped in behind a pre-existing property, and a `$def` reachable by both a
  new and an old path are all still reported.

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
