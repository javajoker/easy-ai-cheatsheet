---
name: py-testing
description: Use when writing, reviewing, or improving Python tests with pytest — designing fixtures, parametrize cases, async tests, mocks via monkeypatch and unittest.mock, factories, snapshot tests, or test organization. Also use when a user asks for a test on a function or module, even if they don't mention pytest specifically.
license: Apache-2.0
metadata:
  sources: "pytest docs, pytest-asyncio docs, Hypothesis docs, Google Python Style Guide"
allowed-tools: Bash(bash:*)
---

# Python Testing

## Available Scripts and Assets

- **`assets/parametrize-test-template.py`** — Canonical pytest scaffold with `parametrize`, fake-clock fixture, `pytest.raises`, and an async test stub. Copy as the starting test file for a new module.
- **`scripts/gen-test.sh`** — Generates a minimal pytest scaffold for a given `module.path:function`. Supports `--async`, `--output`. Run `bash scripts/gen-test.sh --help`.

## Quick Reference

| Need | Reach for |
|---|---|
| Test runner | pytest |
| Parametrize | `@pytest.mark.parametrize` |
| Fixture setup | `@pytest.fixture` |
| Async test | `pytest-asyncio` + `@pytest.mark.asyncio` |
| Mock function | `monkeypatch.setattr` |
| Mock object | `unittest.mock.Mock` / `MagicMock` |
| Expected exception | `with pytest.raises(...)` |
| Property-based | `hypothesis.given(...)` |
| HTTP service | FastAPI `TestClient` / `httpx.AsyncClient` |

---

## pytest by Default

Use **pytest**. It has fewer ceremonies than `unittest`, better assertions
(via assertion-rewriting), parametrize, and a fixture model that scales.

```python
# tests/test_user.py
def test_returns_normalized_email():
    user = User(email="Alice@EXAMPLE.com")
    assert user.normalized_email == "alice@example.com"
```

No `assertEqual` ceremony — `assert` with rewriting gives readable failures.

---

## Test Names Describe Behaviour

```python
# Bad
def test_user(): ...
def test_1(): ...

# Good
def test_returns_normalized_email_for_mixed_case(): ...
def test_raises_validation_error_when_email_missing(): ...
```

A test's name should let the developer who broke it understand the failure
without reading the body.

---

## Parametrize Shared Logic

When several cases share the same code path:

```python
import pytest

@pytest.mark.parametrize(
    ("input", "expected"),
    [
        ("foo", "FOO"),
        ("", ""),
        ("HÁY", "HÁY"),
    ],
)
def test_upper(input, expected):
    assert upper(input) == expected
```

Use `pytest.param(..., id="descriptive")` for named cases. Parametrize is the
right tool when cases differ only in input/output; if cases need different
setup or assertions, write separate tests.

---

## Fixtures

A fixture is a function that produces a value for tests. Pytest injects by
name match.

```python
@pytest.fixture
def db():
    conn = create_test_db()
    try:
        yield conn
    finally:
        conn.close()

def test_create_user(db):
    user = create_user(db, email="a@b")
    assert user.id
```

The `yield` form is the setup-and-teardown shape. The fixture's value is
whatever it yields; cleanup runs after the test.

Scope controls how often the fixture is constructed:

```python
@pytest.fixture(scope="session")   # once per test session
def app(): ...

@pytest.fixture(scope="module")    # once per file
def db_schema(): ...

@pytest.fixture                    # default: per test (most isolated)
def db(): ...
```

Default to function scope. Higher scopes are an optimization; they make tests
non-isolated and trade cleanness for speed.

---

## `conftest.py` for Shared Fixtures

Fixtures live in `conftest.py` at the directory level. Anything in the
nearest ancestor `conftest.py` is available without import:

```
tests/
  conftest.py        # session-wide app, db
  user/
    conftest.py      # user-specific fixtures
    test_user.py
```

Don't put logic in `conftest.py` beyond fixtures and the occasional
`pytest_*` hook.

---

## Async Tests

Install `pytest-asyncio`. Mark async tests:

```python
import pytest

@pytest.mark.asyncio
async def test_async_fetch():
    result = await fetch_user("1")
    assert result.id == "1"
```

Or set `asyncio_mode = "auto"` in `pyproject.toml` so every `async def test_*`
is treated as async — eliminates the marker boilerplate.

```toml
[tool.pytest.ini_options]
asyncio_mode = "auto"
```

For async fixtures, prefix with `async def` and the consumer gets the
awaited value:

```python
@pytest.fixture
async def db():
    conn = await create_async_db()
    yield conn
    await conn.close()

async def test_save(db):
    await save(db, item)
```

---

## Expected Exceptions

```python
import pytest

def test_raises_on_invalid():
    with pytest.raises(ValueError, match="invalid"):
        parse("not a number")

@pytest.mark.asyncio
async def test_raises_on_timeout():
    with pytest.raises(asyncio.TimeoutError):
        await fetch_with_timeout(url, timeout=0.001)
```

`match` does a regex search on the exception message. Combine with checking
the exception attributes for a stronger assertion:

```python
with pytest.raises(NotFoundError) as exc_info:
    load_user("nope")
assert exc_info.value.resource == "user"
```

---

## Mocking: Prefer Real, Then Fake, Then Mock

Order of preference:

1. **Real** in a test container (sqlite for SQL tests, ephemeral Redis).
2. **In-memory fake** that satisfies the same `Protocol`.
3. **`monkeypatch.setattr`** for a single function on a real module.
4. **`unittest.mock`** as a last resort.

```python
# Preferred — inject a fake via Protocol
class FakeUserRepo:
    def __init__(self):
        self._users = {}
    def find_by_id(self, id):
        return self._users.get(id)
    def save(self, user):
        self._users[user.id] = user

def test_service_creates_user():
    service = UserService(FakeUserRepo())
    user = service.create(email="a@b")
    assert user.id
```

```python
# monkeypatch — single function replacement
def test_fetch_handles_timeout(monkeypatch):
    def fake_fetch(url):
        raise TimeoutError
    monkeypatch.setattr("myapp.client.fetch", fake_fetch)
    ...
```

Use `unittest.mock.Mock` only for genuinely tricky boundaries (a third-party
library you can't subclass). The more mocking, the brittler the test.

---

## Time and Randomness

Pass them in. The unit under test takes a `clock` or `random` parameter; the
test passes a fixed value:

```python
def test_session_expiry():
    clock = FakeClock(now=1000)
    session = Session(clock=clock, ttl=60)
    clock.advance(61)
    assert not session.is_valid()
```

For tests where injection isn't practical, `freezegun` or
`pytest-mock`'s `mocker.patch("time.time", return_value=...)` work.

---

## Hypothesis for Property-Based Tests

For functions where you can describe a property that should hold across all
inputs, use Hypothesis:

```python
from hypothesis import given
from hypothesis import strategies as st

@given(st.text())
def test_roundtrip(s):
    assert decode(encode(s)) == s
```

Hypothesis finds edge cases (empty string, unicode, surrogate pairs) that
hand-written tests miss. Reserve for genuine properties — don't use for
example-based tests.

---

## HTTP Service Tests

FastAPI ships `TestClient`:

```python
from fastapi.testclient import TestClient
from myapp.main import app

client = TestClient(app)

def test_get_user_returns_404_for_missing():
    response = client.get("/users/nope")
    assert response.status_code == 404
    assert response.json() == {"resource": "user"}
```

For async-aware testing, use `httpx.AsyncClient` with FastAPI's `app` as the
transport — see [py-http](../py-http/SKILL.md).

---

## Test Layout

```
src/myapp/
  user/
    repository.py
    service.py
tests/
  conftest.py
  user/
    test_repository.py
    test_service.py
```

Mirror the source tree. Each test file targets one source file. Don't mix
unit and integration tests in the same file — separate by `tests/unit/` and
`tests/integration/`, or use markers.

---

## Snapshot Tests: Reserve for Stable Outputs

`syrupy` and `pytest-snapshot` are tempting because they're easy. They're
hard to maintain because every refactor that touches output prompts a "just
update the snapshot" reflex that erases the test's signal.

Use snapshots only for genuinely large, stable outputs (a generated config,
a normalized AST). For anything else, write explicit assertions.

---

## Coverage: a Floor

`pytest --cov=myapp --cov-report=term-missing`. Set a CI floor (e.g. 70 %) to
catch regressions; don't celebrate the number.

Lines covered with no assertions are not tested. Branch coverage
(`--cov-branch`) catches some of these, but assertion-content is what matters.

---

## Quick Reference

| Question | Default |
|---|---|
| Runner | pytest |
| Async marker | `@pytest.mark.asyncio` or `asyncio_mode = "auto"` |
| Many cases, same path | `@pytest.mark.parametrize` |
| Setup / teardown | `@pytest.fixture` + `yield` |
| Shared fixtures | `conftest.py` |
| Exception | `pytest.raises(...)` |
| Time / random | Inject; fall back to `freezegun` |
| Property-based | `hypothesis.given(...)` |

## Related Skills

- **Async**: [py-async](../py-async/SKILL.md) for async test patterns.
- **Error handling**: [py-error-handling](../py-error-handling/SKILL.md) for `pytest.raises`.
- **Classes**: [py-classes](../py-classes/SKILL.md) for `Protocol`-based fakes.
- **HTTP**: [py-http](../py-http/SKILL.md) for FastAPI `TestClient`.
- **Naming**: [py-naming](../py-naming/SKILL.md) for test file naming.
- **Linting**: [py-linting](../py-linting/SKILL.md) for `pytest` rules in Ruff.
