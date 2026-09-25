PYTHON ?= python3
RELEASE := ./release.py
BUMP_PARTS := patch minor major
DOCS_DIR ?= ../traust/docs

.PHONY: help setup sync hooks lint lint-fix test storage-check check-release status bump docs $(BUMP_PARTS)

help:
	@echo "Targets ($(notdir $(CURDIR))):"
	@echo "  make setup          — uv sync + enable .githooks (run once per clone)"
	@echo "  make sync           — uv sync only"
	@echo "  make hooks          — git config core.hooksPath .githooks"
	@echo "  make lint           — ruff check + format --check"
	@echo "  make lint-fix       — ruff check --fix + format"
	@echo "  make test           — pytest tests (PostgreSQL optional)"
	@echo "  make check-release  — VERSION + CHANGELOG gate for current branch vs main"
	@echo "  make status         — current version, tag, git state"
	@echo "  make bump patch|minor|major — bump VERSION + pyproject.toml"
	@echo "  make docs           — regenerate DDL model docs (DOCS_DIR=$(DOCS_DIR))"

setup: sync hooks
	@echo "ready — local hooks enabled (.githooks). Bypass: git commit --no-verify"

sync:
	uv sync

hooks:
	git config core.hooksPath .githooks
	@chmod +x .githooks/* 2>/dev/null || true

lint:
	uv run ruff check .
	uv run ruff format --check .

lint-fix:
	uv run ruff check --fix .
	uv run ruff format .

storage-check:
	uv run pytest tests/test_storage_sql.py tests/test_compat.py -q

test:
	uv run pytest tests/ -q

docs:
	@if [ ! -d "$(DOCS_DIR)" ]; then \
		echo "DOCS_DIR '$(DOCS_DIR)' does not exist; pass DOCS_DIR=/path/to/docs" >&2; \
		exit 1; \
	fi
	uv run python -m traust_contracts.v1.storage.build_storage_ddl_model \
		--out "$(DOCS_DIR)/storage-v1-ddl-model.md"
	uv run python -m traust_contracts.v1.ledger.build_ledger_ddl_model \
		--out "$(DOCS_DIR)/ledger-v1-ddl-model.md"

check-release:
	@base="$${RELEASE_BASE:-origin/main}"; \
	head="$${RELEASE_HEAD:-HEAD}"; \
	$(PYTHON) ci/gates.py mr "$$base" "$$head"

$(BUMP_PARTS):
	@:

status:
	$(PYTHON) $(RELEASE) status

bump:
	@part="$(filter $(BUMP_PARTS),$(MAKECMDGOALS))"; \
	if [ -z "$$part" ]; then \
		echo "usage: make bump patch|minor|major" >&2; \
		exit 1; \
	fi; \
	$(PYTHON) $(RELEASE) bump $$part
