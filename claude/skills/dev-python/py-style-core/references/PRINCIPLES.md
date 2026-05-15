# Style Principles Reference

The five priority principles for Python style, in the order they apply when
they conflict.

## 1. Clarity

The code's purpose and rationale must be clear to a reader who is not the
author.

- Descriptive names over short names.
- Comment *why*, not *what*.
- View clarity through the reader's lens, not the author's.
- Code is read many more times than it is written.

```python
# Good — clear purpose
def charge_customer(customer_id: str, amount_cents: int) -> str: ...

# Bad — unclear, repeats noun, mixes intent
def charge_charge_for_cust(cust_id: str, amt: int) -> str: ...
```

## 2. Simplicity

Code should accomplish goals in the simplest way possible.

Simple code:

- Reads top to bottom.
- Doesn't assume prior knowledge of clever idioms.
- Has no unnecessary abstraction.
- May be mutually exclusive with "clever" code.

### Least Mechanism

When several mechanisms can express the same idea, prefer the most standard:

1. Core language constructs (`for`, `if`, comprehensions, generators).
2. Standard library (`pathlib`, `collections`, `itertools`).
3. Well-known third-party (`pydantic`, `httpx`).
4. Rolling your own — only when 1, 2, and 3 don't suffice.

```python
# Good — stdlib
from pathlib import Path
content = Path("README.md").read_text()

# Bad — reach for third-party when stdlib does the job
import some_io_lib
content = some_io_lib.read("README.md")
```

## 3. Concision

High signal-to-noise ratio.

- Avoid repetition.
- Avoid extraneous syntax.
- Avoid unnecessary abstraction layers.

```python
# Good — flat, signal-only
if not user.is_active:
    raise InactiveUserError(user.id)

# Bad — same content, more noise
if user.is_active == False:
    raise InactiveUserError(user_id=user.id)
```

Concision is about the *useful* bytes. A confusing one-liner is not concise.

## 4. Maintainability

Code is modified many more times than it is written.

Maintainable code:

- Has APIs that grow gracefully.
- Uses predictable names (same concept = same name everywhere).
- Minimizes coupling and hidden dependencies.
- Has tests with clear diagnostics.

```python
# Bad — critical detail (return type) hidden, mutable default lurking
def fetch(id, opts={}): ...

# Good — explicit type, no mutable default
def fetch(id: str, opts: dict | None = None) -> User: ...
```

## 5. Consistency

Code should look and behave like similar code in the codebase.

- Module-level consistency is most important.
- When two principles tie, break in favor of consistency.
- Never override documented style principles for consistency.

If the project uses Google-style docstrings and your new module uses NumPy
style, the new module is the odd one out — and readers pay the cost.

## Resolving Conflicts

When two principles disagree:

| Conflict | Wins |
|---|---|
| Clarity vs Simplicity | Clarity |
| Clarity vs Concision | Clarity |
| Simplicity vs Concision | Simplicity |
| Any principle vs Consistency | The principle |
| Concision vs Maintainability | Maintainability |
| Consistency within file vs across project | Project |

When in doubt, ask: "If I came back to this code in six months without
context, would I understand it?"
