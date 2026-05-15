---
name: py-functions
description: Use when designing or reviewing Python function signatures — positional vs keyword-only, default arguments (especially the mutable-default trap), `*args`/`**kwargs`, type-annotated parameters and returns, single-purpose function size, overloads with `typing.overload`, and closures vs functools.partial.
license: Apache-2.0
metadata:
  sources: "PEP 8, PEP 3102 (keyword-only), PEP 570 (positional-only), Google Python Style Guide"
---

# Python Functions

## Annotate Public Signatures

Every public function and method has type hints on parameters and return.
Mypy's `disallow_untyped_defs = true` enforces it.

```python
def fetch_user(user_id: str) -> User: ...

async def list_orders(user_id: str, *, limit: int = 50) -> list[Order]: ...
```

For internal one-line helpers, inference is usually fine — but the cost of
annotating is low and the benefit (refactor safety, IDE help) is high.

---

## The Mutable-Default Trap

Default arguments evaluate **once**, at function definition. Mutable defaults
are shared across calls:

```python
# Bad
def add_item(item, items=[]):
    items.append(item)
    return items

add_item("a")            # ["a"]
add_item("b")            # ["a", "b"] — surprised?

# Good — sentinel + initialize inside
def add_item(item, items=None):
    if items is None:
        items = []
    items.append(item)
    return items
```

Applies to `[]`, `{}`, `set()`, custom objects — anything mutable. Lint rule:
`B006` (flake8-bugbear / Ruff).

---

## Keyword-Only Arguments

Force the caller to name arguments past a `*` marker:

```python
def create_user(
    name: str,
    email: str,
    *,
    is_admin: bool = False,
    active: bool = True,
) -> User: ...

create_user("Ada", "a@b", is_admin=True)        # ok
create_user("Ada", "a@b", True)                  # TypeError
```

This is the cure for "boolean trap" call sites. Use it whenever a parameter is:

- A bool.
- An optional flag the reader can't decode from position.
- A configuration value with a meaningful default.

Default after 0–3 positional, mandatory keyword for anything that's a flag.

---

## Positional-Only Arguments

The `/` marker (PEP 570, 3.8+) forces positional. Mostly useful for library
APIs that want to free up the parameter name for `**kwargs` use:

```python
def update(obj, /, **fields):
    """First arg is the object; remaining are fields to update."""
```

Rare in application code; common in stdlib (`dict.get(key, default, /)`).

---

## Signature Shape: 0–3 Positional, Else Keywords

| Count | Shape |
|---|---|
| 0–3 simple, ordered, obvious | positional |
| ≥ 4, or any boolean / optional / config-like | keyword-only |

```python
# Bad
def create_user(name, email, is_admin, active): ...
create_user("Ada", "a@b", False, True)

# Good
def create_user(name: str, email: str, *, is_admin: bool = False, active: bool = True): ...
create_user("Ada", "a@b", active=True)
```

---

## `*args` and `**kwargs`: Sparingly

Variadic arguments are useful for wrappers and for genuinely variadic APIs
(`print`, `min`). For ordinary functions, an explicit signature is clearer.

```python
# Bad
def process(**kwargs):
    name = kwargs["name"]
    email = kwargs["email"]
    ...

# Good
def process(name: str, email: str) -> None: ...
```

When forwarding to another callable, type with `ParamSpec` to preserve the
inner signature (see [py-typing](../py-typing/SKILL.md)):

```python
from typing import ParamSpec, TypeVar, Callable
P = ParamSpec("P")
R = TypeVar("R")

def log_calls(fn: Callable[P, R]) -> Callable[P, R]:
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
        return fn(*args, **kwargs)
    return wrapper
```

---

## `typing.overload` for Variant Returns

When the return type depends on the input type, use `@overload`:

```python
from typing import overload

@overload
def parse(input: str) -> str: ...
@overload
def parse(input: int) -> int: ...
def parse(input: str | int) -> str | int:
    return input
```

Only the implementation has runtime logic; the overloads exist for type
checking. Don't reach for `overload` until a generic or union return can't
express the contract.

---

## Pure Functions Where Possible

A pure function returns the same output for the same input, mutates nothing,
and has no I/O. Most logic in well-designed code is pure; impurity sits at the
edges (DB, HTTP, time, randomness).

```python
# Bad — mutates input
def add_total(cart):
    cart["total"] = sum(item["price"] for item in cart["items"])
    return cart

# Good — pure
def with_total(cart):
    total = sum(item["price"] for item in cart["items"])
    return {**cart, "total": total}
```

---

## Function Length

Aim for under ~30 lines. A function that's 80 lines with three local helper
functions and two `# Step N:` comments wants to be three functions.

A function does one thing at one level of abstraction. "Authenticate, parse
the body, validate, save, send email, return response" is six things.

---

## Returns

A function returns one logical thing. If you reach for `return user, error`,
the function probably has two responsibilities, or the error should be raised
not returned.

```python
# Bad
def find(id) -> tuple[User | None, str | None]:
    ...

# Good — raise, or use Optional
def find(id) -> User:
    ...   # raise NotFoundError if missing

def find_optional(id) -> User | None:
    ...
```

A tuple return is fine when the tuple really is the result (a point, a
key/value pair, a min/max).

---

## Decorators: When and Why

A decorator wraps a function with cross-cutting behavior (logging,
authorization, caching, retries). Use them when the cross-cut is genuinely
orthogonal to the function's logic.

```python
from functools import wraps

def retry(times: int = 3):
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            last_exc = None
            for _ in range(times):
                try:
                    return fn(*args, **kwargs)
                except Exception as exc:
                    last_exc = exc
            raise last_exc
        return wrapper
    return decorator

@retry(times=3)
def fetch(url): ...
```

`@wraps(fn)` preserves `__name__`, `__doc__`, and the wrapped signature (for
introspection). Don't skip it.

---

## Closures vs `functools.partial`

For binding arguments to a function:

```python
from functools import partial

# functools.partial — clearest when binding a few args
times_two = partial(operator.mul, 2)

# Closure — clearest when the body has its own logic
def make_validator(min_len):
    def validate(s):
        return len(s) >= min_len
    return validate
```

`partial` for argument binding, closures for new logic. Don't mix the two
patterns in the same module.

---

## Don't Use `lambda` for Anything Non-Trivial

```python
# Acceptable — short, used in-place
items.sort(key=lambda x: x.priority)

# Bad — multi-statement intent crammed into lambda
key = lambda x: (x.priority, -x.created_at, x.id)
```

If the lambda body would benefit from a name, give it one:

```python
def by_priority_recent(x):
    return (x.priority, -x.created_at, x.id)

items.sort(key=by_priority_recent)
```

---

## Quick Reference

| Question | Default |
|---|---|
| Annotate types? | Yes |
| Mutable default? | Never — use `None` sentinel |
| > 3 args? | Keyword-only past `*` |
| Boolean arg? | Keyword-only |
| Variant return | `@overload` |
| Mutate args? | Avoid; return new |
| Length | Under ~30 lines |
| Decorator cleanup | `@wraps(fn)` |

## Related Skills

- **Style core**: [py-style-core](../py-style-core/SKILL.md) for the broader baseline.
- **Typing**: [py-typing](../py-typing/SKILL.md) for `ParamSpec` and `overload`.
- **Naming**: [py-naming](../py-naming/SKILL.md) for function verbs.
- **Classes**: [py-classes](../py-classes/SKILL.md) for method signature conventions.
- **Documentation**: [py-documentation](../py-documentation/SKILL.md) for docstring on signatures.
