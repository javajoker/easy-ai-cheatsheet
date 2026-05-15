---
name: py-control-flow
description: Use when writing or refactoring control flow in Python — early returns, guard clauses, `match` statement (structural pattern matching), walrus operator, comprehensions vs loops, ternary expressions, or `for/else` and `while/else`. Also use when reviewing nested-conditional code or when the user asks "is there a more Pythonic way?".
license: Apache-2.0
compatibility: Python 3.10+ for `match`. 3.8+ for walrus `:=`.
metadata:
  sources: "PEP 634 (match), PEP 572 (walrus), Google Python Style Guide"
---

# Python Control Flow

## Early Return

Push special cases to the top. Keep the main path at the lowest indent.

```python
# Bad
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

# Good
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

## `if`/`elif` vs Ternary

| Need | Reach for |
|---|---|
| Single condition, short branches | Ternary `a if cond else b` |
| Multiple conditions or long branches | `if`/`elif`/`else` |
| Many discriminated cases | `match` |
| Map a key to a value | dict lookup |

```python
# Good
label = "admin" if user.is_admin else "user"

# Bad — chained ternaries are illegible
grade = "A" if s >= 90 else "B" if s >= 80 else "C" if s >= 70 else "F"

# Good — explicit ladder
def grade(s):
    if s >= 90: return "A"
    if s >= 80: return "B"
    if s >= 70: return "C"
    return "F"
```

For lookups, dict beats `if` chain:

```python
LABELS = {"pending": "In Progress", "active": "Active", "archived": "Archived"}
label = LABELS[status]
```

---

## `match` for Structural Patterns

The `match` statement (3.10+) is for *destructuring* and *exhaustive*
branching, not for replacing every `if`/`elif`.

```python
def render(event):
    match event:
        case {"kind": "created", "user": user_id}:
            return on_created(user_id)
        case {"kind": "updated", "user": user_id, "diff": diff}:
            return on_updated(user_id, diff)
        case {"kind": "deleted", "user": user_id}:
            return on_deleted(user_id)
        case _:
            raise ValueError(f"unknown event: {event}")
```

Patterns that match: literal, name (binds), wildcard `_`, sequence
`[a, b, *rest]`, mapping `{"key": pat}`, class `Point(x=0, y=y)`, `or` patterns
`1 | 2 | 3`, guarded `case x if x > 0`.

When the branches are flat predicate checks with no destructuring, `if`/`elif`
is shorter and clearer.

---

## Walrus `:=`

Assignment-as-expression. Useful when you'd otherwise call `f()` twice or
split a clean condition across lines:

```python
# Bad — double call
if expensive_lookup():
    use(expensive_lookup())

# Good
if value := expensive_lookup():
    use(value)

# Bad — split logic
chunk = f.read(8192)
while chunk:
    process(chunk)
    chunk = f.read(8192)

# Good
while chunk := f.read(8192):
    process(chunk)
```

Don't sprinkle `:=` across normal assignments. It pays its readability cost
only when it removes duplication or merges a setup-and-test idiom.

---

## Loops: Pick the Right One

| Loop | When |
|---|---|
| `for x in iterable` | Iterating items |
| `for i, x in enumerate(items)` | Need the index too |
| `for a, b in zip(xs, ys)` | Iterate pairs (use `strict=True` on 3.10+) |
| `while condition` | Indefinite, condition-driven |
| `while True` + `break` | Loop with non-trivial exit logic |

Don't index-loop unless you need the index:

```python
# Bad
for i in range(len(items)):
    process(items[i])

# Good
for item in items:
    process(item)

# Good — index needed
for i, item in enumerate(items):
    process(i, item)
```

`zip(xs, ys, strict=True)` (3.10+) raises if the iterables differ in length —
catches a class of silent bugs.

---

## `for`/`while` `else`

Rarely seen, often confusing. The `else` clause runs only if the loop
**didn't** break.

```python
for item in items:
    if matches(item):
        result = item
        break
else:
    raise NotFoundError
```

Equivalent and clearer:

```python
for item in items:
    if matches(item):
        break
else:
    raise NotFoundError
result = item
```

Or:

```python
matching = next((x for x in items if matches(x)), None)
if matching is None:
    raise NotFoundError
```

Use `for/else` only when it genuinely reads better. Many teams ban it outright.

---

## Comprehensions vs Loops

A comprehension is shorter and (often) faster than the equivalent loop, when
the body is one expression.

```python
# Good
emails = [u.email for u in users if u.is_active]

# Bad — same effect, more lines
emails = []
for u in users:
    if u.is_active:
        emails.append(u.email)

# Bad — comprehension overstuffed
result = [process(u, normalize(transform(u.data))) for u in users if u.is_active and u.age > 18 and u.country == "US"]
```

Rules of thumb:

- Single-condition filter: comprehension.
- Single-expression body: comprehension.
- Multi-statement body, or any side effect: regular loop.
- Nested-loop comprehensions: up to two levels, max.

`map` and `filter` exist but read less naturally than comprehensions in modern
Python.

---

## Dict and Set Comprehensions

```python
# Map id → user
by_id = {u.id: u for u in users}

# Unique emails
emails = {u.email for u in users}

# Build a dict from two iterables
config = {k: v for k, v in zip(keys, values, strict=True)}
```

Generator expressions are similar with `()`:

```python
total = sum(u.balance for u in users)   # no intermediate list
```

Use generators when the result is consumed once and the dataset is large.

---

## Sentinel Values

A unique sentinel object distinguishes "not provided" from `None`:

```python
_MISSING = object()

def get(d, key, default=_MISSING):
    if key in d:
        return d[key]
    if default is _MISSING:
        raise KeyError(key)
    return default
```

For the type-checker, `typing.Sentinel` and PEP 661 are still in development;
the `object()` idiom is the pragmatic stopgap.

---

## Don't Mix Assignment and Side Effects

```python
# Bad — readers miss the side effect
if (result := db.execute(query)).rowcount > 0:
    ...

# Good — separate
result = db.execute(query)
if result.rowcount > 0:
    ...
```

Walrus is for *value-and-test*, not for hiding stateful operations.

---

## `break`, `continue`, `pass`

- `break` — exit the loop.
- `continue` — skip to next iteration.
- `pass` — do nothing (placeholder).

Use `continue` to flatten a loop body:

```python
# Good
for item in items:
    if not item.is_valid:
        continue
    if item.is_processed:
        continue
    process(item)
```

`pass` is fine in stub functions or empty `except` blocks during incremental
implementation, but a permanent `except SomeError: pass` is a code smell.

---

## Quick Reference

| Want | Default |
|---|---|
| Flatten nested ifs | Early return |
| Lookup key → value | Dict |
| Destructure / exhaustive | `match` |
| Predicate ladder | `if`/`elif` |
| Default for missing | `dict.get(k, default)` |
| Single-expr loop | Comprehension |
| Big aggregation | Generator |
| Iterate paired | `zip(strict=True)` |

## Related Skills

- **Style core**: [py-style-core](../py-style-core/SKILL.md) for nesting and truthiness.
- **Functions**: [py-functions](../py-functions/SKILL.md) for guard-clause patterns.
- **Iterators**: [py-iterators-generators](../py-iterators-generators/SKILL.md) for generator expressions and itertools.
- **Typing**: [py-typing](../py-typing/SKILL.md) for exhaustive narrowing.
- **Error handling**: [py-error-handling](../py-error-handling/SKILL.md) for raise-on-invalid guard clauses.
