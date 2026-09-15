"""Shared test fixtures."""

import warnings
from typing import Never

import pytest

POSTGRES_DSN = "postgresql://traust:traust-test-only@127.0.0.1:5432/traust_test"
POSTGRES_SETUP = (
    "Run:\n  podman run --name traust-postgres --rm -d "
    "-e POSTGRES_USER=traust -e POSTGRES_PASSWORD=traust-test-only "
    "-e POSTGRES_DB=traust_test -p 127.0.0.1:5432:5432 "
    "-v traust-postgres-data:/var/lib/postgresql/data docker.io/library/postgres:16"
)


def skip_postgres(reason: str) -> Never:
    warnings.warn(
        f"PostgreSQL E2E skipped: {reason}. {POSTGRES_SETUP}",
        pytest.PytestWarning,
        stacklevel=2,
    )
    pytest.skip(reason)


@pytest.fixture(scope="session")
def postgres_dsn() -> str:
    try:
        import psycopg
    except ImportError:
        skip_postgres("psycopg is not installed")
    try:
        with psycopg.connect(POSTGRES_DSN, connect_timeout=2):
            pass
    except psycopg.OperationalError:
        skip_postgres("local database is unavailable")
    return POSTGRES_DSN
