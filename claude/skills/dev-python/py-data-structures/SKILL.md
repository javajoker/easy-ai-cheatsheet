---
name: py-data-structures
description: Use when choosing between list, dict, set, tuple, dataclass, namedtuple, frozenset, deque, defaultdict, Counter, or OrderedDict in Python. Also use when designing data shapes, deciding between mutable and immutable, applying ReadonlyDict-style patterns, or auditing accidental mutation at module scope.
license: Apache-2.0
metadata:
  sources: "Python docs (collections), Fluent Python, Google Python Style Guide"
---

# Python Data Structures

## Pick the Right Container

| Need | Container |
|---|---|
| Ordered, mutable, by-index | `list` |
| Ordered, immutable | `tuple` |
| Key → value, ordered (3.7+) | `dict` |
| Unordered unique items | `set` |
| Immutable set | `frozenset` |
| Fast append/pop on both ends | `collections.deque` |
| Auto-default value for missing key | `collections.defaultdict` |
| Multi-set / frequency table | `collections.Counter` |
| Fixed-shape named record | `@dataclass(frozen=True)` or `NamedTuple` |
| Variable-key JSON-shaped record | `TypedDict` |

`dict` preserves insertion order since 3.7 — `OrderedDict` is rarely needed.
Use it only when you need its extra methods (`move_to_end`).

---

## `dataclass` for Records

Replace ad-hoc dicts and tuples with `@dataclass` for structured records:

```python
from dataclasses import dataclass

@dataclass(frozen=True, slots=True)
class User:
    id: str
    email: str
    is_admin: bool = False
```

`frozen=True` makes instances immutable (raises on assignment). `slots=True`
(3.10+) reduces memory and prevents attribute typos at construction.

Use `@dataclass` for value-like records. Use a plain class when behavior
matters more than fields (see [py-classes](../py-classes/SKILL.md)).

---

## `NamedTuple` for Tuple-Compatible Records

```python
from typing import NamedTuple

class Point(NamedTuple):
    x: float
    y: float

p = Point(1.0, 2.0)
p.x, p.y           # by name
p[0], p[1]         # by index — same data
```

NamedTuple is `tuple`-compatible: comparable, hashable, unpackable. Use it
when interop with tuple APIs matters (a function expects a 2-tuple, you want
to give names without breaking the contract).

For most application code, `@dataclass(frozen=True)` reads better. NamedTuple
is for tuple-shaped data.

---

## `dict` vs `dataclass` vs `TypedDict`

```python
# Dict — dynamic keys, untyped
user = {"id": "u1", "email": "a@b"}

# TypedDict — dict shape with type-check
class UserDict(TypedDict):
    id: str
    email: str

# Dataclass — record with optional behavior
@dataclass(frozen=True)
class User:
    id: str
    email: str
```

Rule of thumb:

- **Plain `dict`** for genuinely dynamic content (parsed JSON, untyped config).
- **`TypedDict`** when the shape is fixed but you need dict semantics (JSON
  serialization without conversion).
- **`@dataclass`** for application records with methods, validation, or
  immutability.

---

## `set` for Membership

`x in list` is O(n). `x in set` is O(1). For repeated lookups over the same
collection, use a set:

```python
# Bad in a hot path
allowed = ["admin", "editor", "viewer"]
for u in users:
    if u.role in allowed: ...        # O(n*m)

# Good
allowed = frozenset(("admin", "editor", "viewer"))
for u in users:
    if u.role in allowed: ...        # O(n)
```

`frozenset` for module-level constants — immutable and hashable.

---

## `defaultdict` and `Counter`

```python
from collections import defaultdict, Counter

# Bad — manual default
groups = {}
for item in items:
    key = item.category
    if key not in groups:
        groups[key] = []
    groups[key].append(item)

# Good
groups = defaultdict(list)
for item in items:
    groups[item.category].append(item)

# Counter — frequency table
counts = Counter(item.category for item in items)
counts.most_common(3)
```

When you're done filling, `dict(defaultdict_instance)` converts it back if
you want to lose the auto-default behavior.

---

## `deque` for FIFO

`list.pop(0)` is O(n) — it shifts everything left. For a queue, use `deque`:

```python
from collections import deque

q: deque[Task] = deque()
q.append(task)          # right side
task = q.popleft()      # left side, O(1)
```

Also useful for fixed-size sliding windows with `maxlen`:

```python
recent = deque(maxlen=100)
```

---

## Immutability at the Edge

For values that flow across module boundaries, prefer immutable types:

```python
# Bad — caller can mutate the cache
def get_allowed_roles() -> list[str]:
    return _CACHE

# Good
def get_allowed_roles() -> tuple[str, ...]:
    return _CACHE   # already a tuple

# Good — defensive copy if you must return mutable
def get_allowed_roles() -> list[str]:
    return list(_CACHE)
```

Tuples and frozensets communicate "don't mutate" at the type level. Lists
and sets invite mutation; the caller assumes ownership.

---

## Copying

```python
import copy

shallow = list_a.copy()        # or list_a[:]
shallow = dict_a.copy()        # or {**dict_a}

deep = copy.deepcopy(obj)
```

Shallow copy duplicates the outer container; nested objects are still
shared. Deep copy duplicates everything. Deep copy is expensive — only use
when you'll mutate nested data.

For dataclasses, `dataclasses.replace(obj, **changes)` produces a copy with
selected fields changed:

```python
from dataclasses import replace
updated = replace(user, email="new@b")
```

---

## Avoid Mutation of Module-Level State

Module-level mutable state is shared across the process. A function that
appends to a module-level list creates a memory leak and a race.

```python
# Bad
_SEEN_USERS: list[str] = []

def remember(user_id):
    _SEEN_USERS.append(user_id)

# Good — bounded structure
from collections import deque
_SEEN_USERS: deque[str] = deque(maxlen=10_000)
```

Better still: don't keep state at module scope. Use a class instance, a cache
library, or push it to Redis.

---

## Comprehensions for Construction

```python
# List
emails = [u.email for u in users if u.is_active]

# Dict
by_id = {u.id: u for u in users}

# Set
unique_emails = {u.email for u in users}

# Generator — lazy
total = sum(u.balance for u in users)
```

Generator expressions are the right choice when the result is consumed once
and the source is large — they don't materialize an intermediate list.

---

## Quick Reference

| Need | Reach for |
|---|---|
| Fixed-shape record | `@dataclass(frozen=True, slots=True)` |
| Tuple-shaped record | `NamedTuple` |
| JSON-shaped dict | `TypedDict` |
| Membership check | `set` / `frozenset` |
| Auto-default | `defaultdict` |
| Frequency table | `Counter` |
| Queue | `deque` |
| Sliding window | `deque(maxlen=N)` |
| Immutable copy | `dataclasses.replace` |
| Deep copy | `copy.deepcopy` — sparingly |

## Related Skills

- **Typing**: [py-typing](../py-typing/SKILL.md) for `TypedDict` and generics.
- **Classes**: [py-classes](../py-classes/SKILL.md) for `@dataclass` and slots.
- **Style core**: [py-style-core](../py-style-core/SKILL.md) for truthiness on containers.
- **Control flow**: [py-control-flow](../py-control-flow/SKILL.md) for comprehensions.
- **Performance**: [py-performance](../py-performance/SKILL.md) for hot-path container choice.
- **Iterators**: [py-iterators-generators](../py-iterators-generators/SKILL.md) for lazy data flow.
