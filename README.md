# Traust Contracts

Source of truth for JSON schemas and enums shared across the Traust ecosystem,
plus generated Python bindings, **the configuration contract** (the one place
that knows what config exists and how it loads), and **storage/v1** (the SQL-first
relational contract and reference write protocol).

## Configuration contract

Contracts owns the configuration *mechanism* for the whole stack — mechanism
only, never estate data:

- **MANIFEST** — the authoritative list of config files (name, required/optional,
  schema, typed model). The single source of truth for “what config exists.”
- **Schemas** — `config/v1/*.schema.json`, applied at load time (versioned
  separately from the `schemas/v1` data schemas).
- **Typed sections + `HarnessContext`** — each file parses into a typed model;
  `HarnessContext` is the frozen bundle of them all.
- **The loader** — `load_context()` (resolve the whole context at an entry point)
  and `load_section()` (one file, for narrow feature-gated readers). Resolution is
  `$TRAUST_CONFIG_HOME`, else the documented default `~/.traust/config` — no env
  overrides, no cwd scanning, no second root.

Consumers declare the subset they need and receive an injected `HarnessContext`
(`traust_engine` never loads config itself); the app (`traust`) is the config
*source* (templates + `install_traust`) and resolves the context once per entry
point. One loader → no two callers disagree about “what the config is.”
Optional `storage.yaml` (e.g. `dsn: postgresql://localhost/traust`) loads as
`context.storage`; `load_section("storage")` provides narrow access. Callers open
connections; `Store` receives them and never resolves configuration.
End-to-end architecture: `traust/docs/architecture.md` → *Configuration & context*.

## Install

```bash
uv add "traust-contracts @ git+https://github.com/openshift/traust-contracts.git"
```

Go SDK: see [traust-sdk](https://github.com/openshift/traust-sdk).

## Versioning

Two independent axes:

- **Data-contract version** (`v1`, `v2`, ...) — the shape of schemas/enums
  and everything generated from them. Lives as a real directory; `v2` sits
  beside `v1` once it exists.
- **Package release version** (`VERSION`) — normal semver for this repo.

`traust_contracts.models` / `.enums` / `.paths` alias the current major
(`v1` today). Pin to `traust_contracts.v1.*` directly if the shape must
never move under you.

## Storage contract

`storage/v1` ships readable, authored SQLite/PostgreSQL SQL and a reference
Store with relational projections for all 27 artifact schemas. See the [model and write
semantics](storage/v1/README.md). SQL is grouped by database, entity and operation;
there is no generator, ORM or shipped test corpus.

```python
import sqlite3
from pathlib import Path

from traust_contracts.v1.storage import Store

conn = sqlite3.connect("traust.db")
try:
    store = Store(conn)
    store.init()
    payload = Path("my-vuln-findings.json").read_bytes()
    result = store.ingest("vuln-findings", payload, {"layer_id": "L-demo"})
    print(result.tables)  # artifact and processed finding counts
finally:
    conn.close()
```

The caller owns an idle connection and supplies required `layer_id` metadata;
`project_id` defaults to `local`. Ingest validates exact bytes, stores evidence
and projections in one transaction, and makes identical-byte retries a no-op.
On `IngestError`, the host MUST surface/preserve `error.payload` (the input file
already on disk suffices). The library never chooses a reject path.

SQLite is complete with stdlib. PostgreSQL >=14 uses the optional `postgres`
extra (`psycopg>=3`, requiring libpq or separately installed `psycopg[binary]`).
Both dashboards are live views; no refresh worker is needed. PostgreSQL filters
by session `traust.project_ids`; callers provision tenant permissions.
No foreign keys or cross-artifact atomicity are imposed.

Storage has its own directory major (`storage/v1`) and revision, independent of
package semver. `init()` rejects any version/revision mismatch; it does not migrate
existing databases. Current storage is `v1`, revision 1. Edit SQL directly and
review compatibility; SQL is not byte-pinned.
Tests use focused synthetic inputs plus one real sample under tests, not a
packaged conformance bundle.

## Validate an artifact

```bash
python validate.py --schema report myreport.json
python validate.py --list
```

## Test

```bash
make setup    # uv sync + enable .githooks
make test
```

Or manually:

```bash
uv sync
uv run pytest tests/ -q
```

`tests/test_compat.py` gates breaking JSON Schema changes against the previous tag.
PostgreSQL tests use a fixed local test DSN and create and remove a private schema per test.
They run automatically when `psycopg` and the database are available; otherwise they warn and skip.

## License

Apache License 2.0 — see [`LICENSE`](LICENSE).
