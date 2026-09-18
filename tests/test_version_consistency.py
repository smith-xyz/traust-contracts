"""`VERSION` and `pyproject.toml` must agree.

The version is stored twice, and a release that bumps only `VERSION` publishes
a tag whose distribution metadata reports the *previous* version. That is what
happened to v0.6.0 here: `VERSION` said 0.6.0 while `pyproject.toml` still said
0.5.0, so `importlib.metadata.version("traust-contracts")` reported 0.5.0 and
every consumer's `traust-contracts>=0.6.0` constraint looked unsatisfied. The
git-tag pin in `[tool.uv.sources]` wins over the constraint, so nothing failed
loudly — the constraint quietly became decorative, and drift checks comparing
installed versions to pins would have reported a skew no syncing could clear.

traust-ledger has carried this test since hitting the same bug twice
(0.13.0 and 0.17.2). Contracts did not, which is why the drift went unnoticed.
"""

from __future__ import annotations

import pathlib
import tomllib

ROOT = pathlib.Path(__file__).resolve().parent.parent


def test_version_file_matches_pyproject() -> None:
    version_file = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
    pyproject = tomllib.loads((ROOT / "pyproject.toml").read_text(encoding="utf-8"))
    assert pyproject["project"]["version"] == version_file, (
        f"VERSION says {version_file} but pyproject.toml says "
        f"{pyproject['project']['version']} — bump both, or the release ships "
        "metadata for the previous version"
    )
