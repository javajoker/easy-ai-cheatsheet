---
name: py-typing
description: Use when writing or reviewing Python type hints — annotations, generics (TypeVar, ParamSpec), Protocol, TypedDict, Literal, Final, NewType, narrowing with isinstance / assert, mypy or pyright configuration. Also use when removing `Any` from a codebase, deciding between `Optional[X]` and `X | None`, or designing a generic helper.
license: Apache-2.0
compatibility: Python 3.10+ (X | Y unions, `match` statement). Some examples use 3.12 generic syntax.
metadata:
  sources: "PEP 484, PEP 585, PEP 604, PEP 612, PEP 695, typing docs, Mypy/Pyright manuals"
---

# Python Typing

## Type-Check the Project

Pick one type checker and configure it strictly:

| Checker | When |
|---|---|
| **Pyright** | Fast, in-editor by default in VS Code (Pylance). |
| **Mypy** | Established, mature, configurable via `pyproject.toml`. |

Both are fine. Don't try to run both — their errors disagree at the margins
and you'll waste time reconciling.

```toml
[tool.mypy]
python_version = "3.12"
strict = true
warn_unused_ignores = true
disallow_untyped_defs = true
no_implicit_reexport = true
plugins = ["pydantic.mypy"]   # if using pydantic v2
```

```toml
[tool.pyright]
pythonVersion = "3.12"
typeCheckingMode = "strict"
reportMissingTypeStubs = "error"
```

---

## Modern Syntax (3.10+)

| Old | Modern |
|---|---|
| `Optional[int]` | `int \| None` |
| `Union[int, str]` | `int \| str` |
| `List[int]` | `list[int]` |
| `Dict[str, int]` | `dict[str, int]` |
| `Tuple[int, ...]` | `tuple[int, ...]` |
| `Type[Foo]` | `type[Foo]` |

If you need to support older Python, keep `from __future__ import annotations`
at the top of each module — that defers annotation evaluation and lets you use
modern syntax everywhere.

```python
from __future__ import annotations

def fetch(ids: list[int]) -> dict[int, str] | None: ...
```

---

## `Any` Is the Escape Hatch

`Any` disables checking. Use it sparingly and isolate it.

```python
# Bad — pretends to be typed
def parse(input: Any) -> Any: ...

# Good — unknown input, narrowed at the edge
def parse(input: object) -> User:
    if not isinstance(input, dict):
        raise TypeError("expected dict")
    return User.model_validate(input)
```

`object` is the right type for "I'll accept anything" — but the checker will
force you to narrow before use, which is the point.

For genuinely untyped third-party code:

```python
import legacy_pkg  # type: ignore[import]
```

Add stubs (`types-<pkg>`) when they exist; the `type: ignore` is a debt.

---

## Generics

For PEP 695 syntax (3.12+):

```python
def first[T](items: list[T]) -> T:
    return items[0]

class Stack[T]:
    def __init__(self) -> None:
        self._data: list[T] = []
    def push(self, item: T) -> None:
        self._data.append(item)
```

For < 3.12, use `TypeVar`:

```python
from typing import TypeVar
T = TypeVar("T")

def first(items: list[T]) -> T:
    return items[0]
```

Constrain when there's a known shape:

```python
T = TypeVar("T", bound=Comparable)
def sort(items: list[T]) -> list[T]: ...
```

---

## Protocols: Structural Typing

A `Protocol` defines a shape; any class that has the matching members
satisfies it, without subclassing.

```python
from typing import Protocol

class UserRepo(Protocol):
    def get_by_id(self, id: str) -> User | None: ...
    def save(self, user: User) -> None: ...

def find_active(repo: UserRepo) -> list[User]:
    ...
```

Anyone who passes an object with those two methods satisfies the type. This is
the canonical way to express "duck-typed" dependencies — useful for tests
(plain class with the methods, no inheritance) and for replacing ABCs in many
cases.

---

## `TypedDict` for JSON-Shaped Objects

When you have JSON-like dicts with fixed key names, use `TypedDict`:

```python
from typing import TypedDict, NotRequired

class UserPayload(TypedDict):
    id: str
    email: str
    name: NotRequired[str]

def render(u: UserPayload) -> str:
    return u["email"]
```

The checker will catch wrong keys, missing required ones, and type mismatches.
For complex shapes, prefer Pydantic — it validates *at runtime*, which
`TypedDict` does not.

---

## `Literal` for Enumerated Values

```python
from typing import Literal

Status = Literal["pending", "active", "archived"]

def set_status(user: User, status: Status) -> None: ...

set_status(user, "active")    # ok
set_status(user, "deleted")   # type error
```

For runtime-enforced enums, use `enum.Enum` or `enum.StrEnum`. `Literal` is
zero-overhead and works on string literals directly — ideal for API
parameters.

---

## `Final` and `NewType`

`Final` marks something as not-reassignable (at type-check time):

```python
from typing import Final

DEFAULT_TIMEOUT: Final = 30
```

`NewType` creates a distinct type at type-check time, while remaining the same
underlying type at runtime:

```python
from typing import NewType

UserId = NewType("UserId", str)
OrderId = NewType("OrderId", str)

def get_user(id: UserId) -> User: ...

uid = UserId("u_123")
get_user(uid)            # ok
get_user("plain_str")    # type error
```

---

## Narrowing

The checker narrows types as you go through guards:

```python
def f(x: int | None) -> int:
    if x is None:
        raise ValueError
    return x + 1            # narrowed to int

def g(x: str | bytes) -> str:
    if isinstance(x, bytes):
        return x.decode()
    return x                 # narrowed to str
```

For complex narrowing logic, use `TypeGuard` (3.10+) or `TypeIs` (3.13+):

```python
from typing import TypeGuard

def is_str_list(x: list[object]) -> TypeGuard[list[str]]:
    return all(isinstance(i, str) for i in x)

if is_str_list(items):
    # items is now list[str]
    ...
```

---

## `assert` for Type Refinement

`assert x is not None` narrows the type in the rest of the scope. But
`assert` is stripped under `python -O`, so don't rely on it for runtime
validation:

```python
def f(x: int | None) -> int:
    assert x is not None     # narrow for the checker
    return x + 1
```

For runtime-enforced narrowing, raise explicitly:

```python
if x is None:
    raise ValueError("x must not be None")
```

---

## `ParamSpec` and `Concatenate`

When typing a decorator that preserves the wrapped function's signature:

```python
from typing import ParamSpec, TypeVar, Callable
P = ParamSpec("P")
R = TypeVar("R")

def log_calls(fn: Callable[P, R]) -> Callable[P, R]:
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
        log.info({"fn": fn.__name__}, "calling")
        return fn(*args, **kwargs)
    return wrapper
```

3.12+ PEP 695 syntax:

```python
def log_calls[**P, R](fn: Callable[P, R]) -> Callable[P, R]: ...
```

---

## Avoid `Callable[..., Any]`

`Callable[..., Any]` accepts anything and returns anything — equivalent to
`Any` for a function. Use `ParamSpec` (if you need to preserve the signature)
or a `Protocol` (if the function has a specific shape).

---

## Quick Reference

| Need | Reach for |
|---|---|
| Optional | `T \| None` |
| Untyped input | `object`, then narrow |
| Type variable | PEP 695 syntax (`def f[T](...)`) on 3.12+, `TypeVar` below |
| Structural type | `Protocol` |
| Fixed-key dict | `TypedDict` |
| Enumerated string | `Literal[...]` or `StrEnum` |
| Distinct alias | `NewType` |
| Type guard | `TypeGuard` / `TypeIs` |
| Generic decorator | `ParamSpec` |

## Related Skills

- **Style core**: [py-style-core](../py-style-core/SKILL.md) for `from __future__ import annotations`.
- **Naming**: [py-naming](../py-naming/SKILL.md) for type-variable conventions.
- **Classes**: [py-classes](../py-classes/SKILL.md) for `@dataclass`, `Protocol`, and ABC.
- **Functions**: [py-functions](../py-functions/SKILL.md) for signature design and Callable typing.
- **Error handling**: [py-error-handling](../py-error-handling/SKILL.md) for raising on narrow-failure.
- **Linting**: [py-linting](../py-linting/SKILL.md) for type-checker config.
