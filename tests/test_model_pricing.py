"""Per-model pricing tiers in the model registry.

A model may declare a cache-hit multiplier (the standard is 0.1x input) and a
long-prompt tier: higher prices for a request whose prompt is over a token
threshold. Both are optional, so existing registries load unchanged.
"""

from __future__ import annotations

from pathlib import Path

import jsonschema
import pytest
import yaml

from traust_contracts.config import LongPromptPricing, load_section


def _registry(models: dict) -> dict:
    return {
        "version": 1,
        "updated": "2026-10-16",
        "tiers": {"haiku-class": {"description": "h"}, "opus-class": {"description": "o"}},
        "providers": {"anthropic": {"data_handling": "test", "models": models}},
        "roles": {
            "r": {
                "floor": "haiku-class",
                "approved": list(models),
                "candidates": [],
                "ledger_validity_writer": False,
            }
        },
    }


def _load(tmp_path: Path, models: dict):
    (tmp_path / "model-registry.yaml").write_text(yaml.safe_dump(_registry(models)))
    return load_section("model-registry.yaml", config_home=tmp_path)


def test_a_plain_entry_still_loads(tmp_path):
    reg = _load(tmp_path, {"m": {"tier": "haiku-class", "batch_eligible": True}})
    m = reg.all_models()["m"]
    assert m.cache_read_multiplier is None and m.long_prompt is None


def test_both_tiers_load_typed(tmp_path):
    reg = _load(
        tmp_path,
        {
            "m": {
                "tier": "haiku-class",
                "batch_eligible": True,
                "price_per_mtok_in": 0.1,
                "price_per_mtok_out": 0.5,
                "cache_read_multiplier": 0.1,
                "long_prompt": {
                    "above_tokens": 100000,
                    "price_per_mtok_in": 0.5,
                    "price_per_mtok_out": 2.5,
                },
            },
            "o": {"tier": "opus-class", "batch_eligible": True, "cache_read_multiplier": 0.05},
        },
    )
    m = reg.all_models()["m"]
    assert isinstance(m.long_prompt, LongPromptPricing)
    assert (m.long_prompt.above_tokens, m.long_prompt.price_per_mtok_out) == (100000, 2.5)
    assert reg.all_models()["o"].cache_read_multiplier == 0.05


@pytest.mark.parametrize(
    "extra",
    [
        {"cache_read_multiplier": 0},
        {"cache_read_multiplier": 1.5},
        {"long_prompt": {"above_tokens": 100000, "price_per_mtok_in": 0.5}},
        {"long_prompt": {"above_tokens": 0, "price_per_mtok_in": 0.5, "price_per_mtok_out": 2.5}},
        {
            "long_prompt": {
                "above_tokens": 1,
                "price_per_mtok_in": 0.5,
                "price_per_mtok_out": 2.5,
                "currency": "usd",
            }
        },
    ],
)
def test_malformed_tiers_are_rejected(tmp_path, extra):
    with pytest.raises(jsonschema.ValidationError):
        _load(tmp_path, {"m": {"tier": "haiku-class", "batch_eligible": True, **extra}})
