---
name: py-style-core
description: Use when working with Python formatting, line length, indentation, blank lines, trailing whitespace, or core style principles. Also use when a style question isn't covered by a more specific skill, even if the user doesn't reference a specific style rule. Does not cover domain-specific patterns like error handling, naming, or testing (see specialized skills). Acts as fallback when no more specific style skill applies.
license: Apache-2.0
metadata:
  sources: "PEP 8, Google Python Style Guide, Black documentation, Ruff format"
---

# Python Style Core Principles

## Style Principles (Priority Order)

When writing readable Python code, apply these principles in order of importance:

1. **Clarity** — Can a reader understand the code without extra context?
2. **Simplicity** — Is this the simplest way to accomplish the goal?
3. **Concision** — Does every line earn its place?
4. **Maintainability** — Will this be easy to modify later?
5. **Consistency** — Does it match surrounding code and project conventions?

> Read [references/PRINCIPLES.md](references/PRINCIPLES.md) when resolving conflicts between clarity, simplicity, and concision, or when you need concrete examples of how each principle applies in real Python code.

The Zen of Python (`import this`) is good guidance, not law. "There should be
one — and preferably only one — obvious way to do it" sets the expectation;
clarity sometimes overrides cleverness.

---

## Formatting

Use a formatter. The two real choices:

- **Ruff format** (preferred for new projects) — Black-compatible, very fast,
  pairs naturally with `ruff check`.
- **Black** — established, opinionated, the de facto standard.

Don't debate quote style or comma trailing — the formatter decides. Configure
line length explicitly (88 for Black/Ruff default, 100 if the team prefers).

```toml
# pyproject.toml
[tool.ruff]
line-length = 100
target-version = "py312"

[tool.ruff.format]
quote-style = "double"
```

Run the formatter on save and in CI. A PR that re-formats unrelated lines
because the author hadn't run the formatter is a friction tax on reviewers.

> Read [references/FORMATTING.md](references/FORMATTING.md) when configuring Ruff format or Black, deciding on print width, handling docstring code blocks, or wiring formatting into pre-commit and CI.

---

## Indentation and Whitespace

- 4 spaces per indent. No tabs.
- Two blank lines between top-level definitions; one between methods.
- No trailing whitespace.
- Surround binary operators with single spaces (`x = 1`, `a + b`), but not
  inside keyword-argument defaults in a signature (`def f(x=1):`).

The formatter handles all of this. Don't re-litigate it in code review.

---

## Line Length

Default 88 (Black) or 100 (Ruff config). Hard limit is "what your team agreed
on". When a line wants to be longer, refactor it — extract a local, give it a
name — don't backslash-continue.

```python
# Bad
result = some_function(very_long_argument_name, another_argument, more_args, even_more)

# Good
arguments = (very_long_argument_name, another_argument, more_args, even_more)
result = some_function(*arguments)

# Also good — formatter wraps
result = some_function(
    very_long_argument_name,
    another_argument,
    more_args,
    even_more,
)
```

---

## Reduce Nesting

Push special cases and error paths to the top with early `return` or `raise`.

```python
# Bad — deeply nested
def process(req):
    if req.user:
        if req.user.is_active:
            if req.body:
                return do_work(req.user, req.body)
            else:
                raise ValueError("no body")
        else:
            raise ValueError("inactive")
    else:
        raise ValueError("no user")

# Good — flat
def process(req):
    if not req.user:
        raise ValueError("no user")
    if not req.user.is_active:
        raise ValueError("inactive")
    if not req.body:
        raise ValueError("no body")

    return do_work(req.user, req.body)
```

---

## String Quotes

Pick one quote style (the formatter does this — Ruff/Black default to double
quotes). Use the other quote style to avoid escaping when the string contains
the chosen quote.

```python
# Good
greeting = "Hello"
quoted = 'She said "hello"'

# f-strings for interpolation
msg = f"user {name} signed in at {ts}"

# Triple quotes for multi-line and docstrings
"""Summary line.

Longer body.
"""
```

Don't mix concatenation styles. `"x" + str(y)` is rarely what you want — use
f-strings.

---

## `is` vs `==`

`is` checks identity (same object). `==` checks equality.

Use `is` for `None`, `True`, `False` (singletons):

```python
if value is None: ...
if flag is True: ...   # rare; usually just `if flag:`
```

Use `==` for value comparison:

```python
if name == "alice": ...
if count == 0: ...
```

`if x is "foo"` works "by accident" because of string interning; don't rely on
it.

---

## Truthiness

Python objects have implicit truthiness. Use it for empty-container checks:

```python
# Good
if not items: ...           # empty list
if not response.body: ...   # empty string
if user: ...                # not None and not empty

# Bad — verbose
if len(items) == 0: ...
if response.body == "": ...
if user is not None: ...    # use only when None vs falsy matters
```

When `0` and `None` need to be distinguished, use explicit `is None`:

```python
# Bad — 0 collapses into the fallback
def f(x):
    x = x or 10

# Good
def f(x):
    if x is None:
        x = 10
```

---

## Imports

One import per line for top-level imports. Group as: standard library,
third-party, local. See [py-modules](../py-modules/SKILL.md).

---

## File Layout

A Python module typically reads:

1. Module docstring.
2. `from __future__` imports (if needed).
3. Standard-library imports.
4. Third-party imports.
5. Local imports.
6. Module-level constants (`UPPER_CASE`).
7. Module-level dataclasses and types.
8. Module-level functions and classes.
9. `if __name__ == "__main__":` if it's a script.

Keep files under ~500 lines as a rough guideline.

---

## Quick Reference

| Principle | Key Question |
|-----------|--------------|
| Clarity | Can a reader understand what and why? |
| Simplicity | Is this the simplest approach? |
| Concision | Is the signal-to-noise ratio high? |
| Maintainability | Can this be safely modified later? |
| Consistency | Does this match surrounding code? |

## Related Skills

- **Naming**: See [py-naming](../py-naming/SKILL.md) for PEP 8 naming conventions.
- **Typing**: See [py-typing](../py-typing/SKILL.md) for static type hints.
- **Modules**: See [py-modules](../py-modules/SKILL.md) for import ordering and package layout.
- **Control flow**: See [py-control-flow](../py-control-flow/SKILL.md) for early returns and match.
- **Error handling**: See [py-error-handling](../py-error-handling/SKILL.md) for exception flow.
- **Documentation**: See [py-documentation](../py-documentation/SKILL.md) for docstring conventions.
- **Linting**: See [py-linting](../py-linting/SKILL.md) for Ruff and pre-commit setup.
- **Code review**: See [py-code-review](../py-code-review/SKILL.md) for applying style during PR review.
