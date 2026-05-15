---
name: py-documentation
description: Use when writing or reviewing docstrings in Python — choosing Google / NumPy / Sphinx style, what to document and what to leave to type hints, module-level docstrings, README sections, and `@deprecated` markers. Also use when generating API docs with mkdocstrings or Sphinx.
license: Apache-2.0
metadata:
  sources: "PEP 257, Google Python Style Guide, NumPy docstring guide, Sphinx docs"
allowed-tools: Bash(bash:*)
---

# Python Documentation

## Available Scripts and Assets

- **`scripts/check-docs.sh`** — Scans Python files for public functions and classes (no leading `_`) that lack a docstring as the first statement of the body. Run `bash scripts/check-docs.sh --help` for options. For richer enforcement, add Ruff's `D` (pydocstyle) rules.
- **`assets/doc-template.py`** — Canonical Google-style docstrings for module, function, dataclass, class, and `@deprecated`. Copy when scaffolding the documentation for a new module.

## What to Document

Type hints already document **what** types. Documentation contributes:

- **Why** the function exists.
- **When** to use it vs another function (trade-offs).
- **Constraints** the types can't express (units, ranges, ordering, side
  effects, thread-safety).
- **Examples** for non-obvious call sites.

Don't restate the signature.

```python
# Bad — repeats the name and types
def get_user_by_id(user_id: str) -> User:
    """Get the user by id.

    Args:
        user_id: The user id.

    Returns:
        The user.
    """
    ...

# Good — adds why and constraints
def get_user_by_id(user_id: str) -> User:
    """Load the user from the primary database.

    Bypasses the read-replica cache; use ``get_user_by_id`` from
    ``cached_repo`` when stale data is acceptable.

    Raises:
        NotFoundError: If no user matches the id.
    """
    ...
```

---

## Pick One Style and Stick to It

| Style | Looks like | When |
|---|---|---|
| **Google** | `Args:` / `Returns:` / `Raises:` sections | Most teams; readable raw and rendered |
| **NumPy** | Section headers with dashed underlines | Scientific projects |
| **Sphinx / reStructuredText** | `:param x:` `:returns:` | Older / Sphinx-heavy codebases |

Google style is the most common modern choice; it reads well in source and
renders cleanly via `mkdocstrings` or `sphinx.ext.napoleon`.

```python
def charge(customer_id: str, amount_cents: int) -> str:
    """Charge the customer for the given amount.

    Args:
        customer_id: Stripe customer ID.
        amount_cents: Amount in cents; must be ≥ 50 (Stripe minimum).

    Returns:
        The Stripe charge ID on success.

    Raises:
        InsufficientFundsError: When the card was declined.

    Example:
        >>> charge("cus_123", 1500)
        "ch_abc"
    """
    ...
```

---

## Module Docstrings

The top of every module starts with a docstring. One sentence summary; add
paragraphs if there's more to say.

```python
"""User repository — read and write the ``users`` table.

Provides ``UserRepository``, the primary persistence interface. See
``UserService`` in ``user_service`` for business logic that uses it.
"""

from __future__ import annotations
...
```

Tools like Pydoc and mkdocstrings pick up the module docstring as the page
intro.

---

## Class Docstrings

Document the class after the `class` line. If `__init__` has non-obvious
behaviour, document it there too.

```python
class UserRepository:
    """SQL persistence for ``User`` records.

    Connections are pooled; this class is safe to share across asyncio tasks
    in the same process.

    Attributes:
        pool: The shared asyncpg pool.
    """

    def __init__(self, pool: Pool) -> None:
        self._pool = pool
```

For `@dataclass`, document the class purpose; field documentation can live
in field comments or in a separate `Attributes:` section.

---

## Document the Public API

For an internal module, document the **exported** functions and classes. The
private `_helper` inside the same file usually doesn't need a docstring —
the name and surrounding usage tell the story.

Exception: a private helper with non-obvious logic (algorithm, workaround)
deserves a short comment explaining why.

```python
# private helper
def _detect_pollution(d: dict) -> bool:
    """Check for ``__proto__`` keys before merging."""
    return any(k.startswith("__") for k in d)

def normalize_config(input: object) -> Config:
    """Validate and normalize a user-supplied configuration object.

    Raises:
        ConfigError: On schema violations.
    """
    ...
```

---

## `@deprecated` and Replacement Pointers

Mark deprecated functions and point at the replacement:

```python
import warnings

def fetch_user(user_id: str) -> User:
    """Load a user by id.

    .. deprecated:: 0.5.0
        Use :func:`get_user_by_id` instead.
    """
    warnings.warn(
        "fetch_user is deprecated; use get_user_by_id",
        DeprecationWarning,
        stacklevel=2,
    )
    return get_user_by_id(user_id)
```

Without a replacement pointer, callers have nowhere to go. The
`DeprecationWarning` is shown to library users when they enable warnings
(pytest does by default).

---

## Examples in Docstrings

A short `Example:` (Google style) or `Examples` (NumPy style) section is
the most useful documentation you can add. IDEs render examples on hover.

```python
def build_url(path: str, params: dict[str, str | int]) -> str:
    """Build a URL with query parameters.

    Example:
        >>> build_url("/users", {"page": 2})
        '/users?page=2'
    """
    ...
```

`doctest` can execute these blocks as tests — useful for ensuring examples
stay correct.

Keep examples to under ~5 lines. Anything longer belongs in a README or a
dedicated docs page.

---

## Type Hints Are Documentation

Modern Python docstrings rarely repeat the types — the type hints do that
job. Document the *meaning* and *constraints* the type can't carry.

```python
# Old style — types in the docstring
def fetch(url: str, timeout: float = 5.0) -> bytes:
    """Fetch a URL.

    Args:
        url (str): The URL.
        timeout (float, optional): Seconds. Default 5.0.

    Returns:
        bytes: The body.
    """

# Modern — meaning, not type
def fetch(url: str, timeout: float = 5.0) -> bytes:
    """Fetch the URL and return the response body.

    Args:
        url: Must use ``https://`` — ``http`` raises ``InsecureUrlError``.
        timeout: Seconds before raising ``TimeoutError``. Default 5.

    Raises:
        TimeoutError: If the request takes longer than ``timeout`` seconds.
        InsecureUrlError: If the URL is not HTTPS.
    """
```

---

## README Sections

A package or service README answers, in order:

1. **What it is** — one sentence.
2. **Why it exists** — the problem it solves.
3. **Install / quick start** — minimal copy-pasteable example.
4. **Configuration** — env vars, config files.
5. **API surface** — main exports / endpoints; link to detailed docs.
6. **Development** — install, test, run.
7. **License**.

A README that opens with the install command is failing the reader. Lead
with "this is a library that ___".

---

## Generate Public API Docs

For libraries, generate a docs site:

- **mkdocstrings + MkDocs** — modern, Markdown-native.
- **Sphinx** — established, more configurable.

```bash
mkdocs serve
```

For services, generated OpenAPI from FastAPI route schemas is usually more
valuable than narrative API docs.

---

## Inline Comments

Default to no inline comment. Add one only when removing it would confuse a
reader.

| Comment | Where | What |
|---|---|---|
| Docstring | First statement after `def` / `class` / module | Public-facing documentation |
| `# inline` | Above a line | Non-obvious *why* of the code below |
| `# TODO(name): ...` | Above a line | Tracked deferred work |
| `# FIXME: ...` | Above a line | Known broken; replace ASAP |

---

## Quick Reference

| Question | Default |
|---|---|
| Docstring style | Google |
| Document private helpers? | Only the non-obvious ones |
| Document exported API? | Yes |
| Restate types? | No — they're in the signature |
| First line | Summary, imperative or descriptive, under ~80 chars |
| Examples | Yes, when call shape isn't obvious |
| `@deprecated`? | Yes, with a replacement pointer |
| Inline comments | Only for non-obvious *why* |

## Related Skills

- **Style core**: [py-style-core](../py-style-core/SKILL.md) for module structure.
- **Naming**: [py-naming](../py-naming/SKILL.md) — good names reduce the need for docstrings.
- **Typing**: [py-typing](../py-typing/SKILL.md) for types that document themselves.
- **Functions**: [py-functions](../py-functions/SKILL.md) for signature shape.
- **Linting**: [py-linting](../py-linting/SKILL.md) for `pydocstyle` and Ruff `D` rules.
