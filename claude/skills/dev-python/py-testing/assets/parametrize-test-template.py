"""Canonical pytest parametrize and fixture template.

Copy as the starting scaffold for a new test file. Replace imports and
function names with the module under test.
"""

from __future__ import annotations

import asyncio
from dataclasses import dataclass

import pytest

from myapp.upper_case import upper_case   # replace with real import


# ---------------------------------------------------------------------------
# Table-driven via parametrize: many cases, one code path.

@pytest.mark.parametrize(
    ("name", "input_value", "expected"),
    [
        ("ascii",       "foo", "FOO"),
        ("empty",       "",    ""),
        ("unicode",     "háy", "HÁY"),
        ("mixed_case",  "aBc", "ABC"),
    ],
    ids=lambda v: v if isinstance(v, str) and len(v) < 20 else None,
)
def test_upper_case_returns_uppercased(name: str, input_value: str, expected: str) -> None:
    """upper_case maps the input to its uppercased form."""
    assert upper_case(input_value) == expected


# ---------------------------------------------------------------------------
# Fixture with setup + teardown.

@dataclass
class FakeClock:
    """In-memory clock for tests that need controlled time."""

    now_ms: int = 0
    def advance(self, ms: int) -> None: self.now_ms += ms


@pytest.fixture
def clock() -> FakeClock:
    return FakeClock(now_ms=0)


# ---------------------------------------------------------------------------
# Asserting an expected exception.

def test_upper_case_rejects_none() -> None:
    with pytest.raises(TypeError, match="expected"):
        upper_case(None)   # type: ignore[arg-type]


# ---------------------------------------------------------------------------
# Async test (requires pytest-asyncio + asyncio_mode = "auto", or @pytest.mark.asyncio).

async def _async_double(x: int) -> int:
    await asyncio.sleep(0)
    return x * 2


@pytest.mark.asyncio
async def test_async_double_returns_doubled() -> None:
    assert await _async_double(2) == 4
