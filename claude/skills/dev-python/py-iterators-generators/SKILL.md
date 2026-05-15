---
name: py-iterators-generators
description: Use when writing or reviewing iterators, generators, async generators, generator expressions, or `itertools` usage in Python. Also use when choosing between materialized lists and lazy generators, designing pipelines, or refactoring memory-hungry loops into streaming form.
license: Apache-2.0
metadata:
  sources: "Python docs (itertools, generators), Fluent Python, PEP 525 (async generators)"
---

# Python Iterators and Generators

## When to Reach for a Generator

Use a generator when:

- The source is large enough that materializing into a list would use too
  much memory (DB cursor, log file, network paginated API).
- The consumer might not need every item (find-first patterns, partial
  iteration).
- The iteration has natural laziness (infinite sequences, pipelines).

```python
def stream_lines(path):
    with open(path) as f:
        for line in f:
            yield line.rstrip()

for line in stream_lines("huge.log"):
    if "ERROR" in line:
        print(line)
        break        # short-circuit; no need to read more
```

`yield` makes the function a generator. Each `yield` pauses; the next call
resumes from where it left off.

---

## Generator Expressions

Like list comprehensions, but lazy and parenthesised:

```python
# List — materializes
emails = [u.email for u in users if u.is_active]

# Generator — lazy
emails = (u.email for u in users if u.is_active)

# Common idiom: feed to a consumer
total = sum(u.balance for u in users)            # parens optional inside sum
any_admin = any(u.is_admin for u in users)
```

Generator expressions can be passed directly to functions that accept an
iterable. They don't allocate an intermediate list.

---

## `itertools` Has the Common Cases

| Function | What |
|---|---|
| `chain(a, b)` | Concatenate iterables |
| `chain.from_iterable(iters)` | Flatten one level |
| `groupby(iterable, key)` | Adjacent grouping (sort first if needed) |
| `islice(iter, start, stop, step)` | Slice an iterator |
| `pairwise(iter)` | `(a, b)`, `(b, c)`, `(c, d)` — 3.10+ |
| `accumulate(iter, fn)` | Running aggregate |
| `tee(iter, n)` | Branch an iterator into n |
| `count(start, step)` | Infinite counter |
| `cycle(iter)` | Infinite cycle |
| `repeat(x, n)` | Repeat |
| `product`, `permutations`, `combinations` | Combinatorics |
| `compress(data, selectors)` | Mask filter |
| `dropwhile(p, iter)` / `takewhile(p, iter)` | Predicate-bounded |

```python
from itertools import groupby, pairwise

# Adjacent groups — sort first if not pre-sorted
for status, items in groupby(sorted(events, key=lambda e: e.status), key=lambda e: e.status):
    handle(status, list(items))

# Pairs of consecutive items
for a, b in pairwise([1, 2, 3, 4]):
    print(a, b)   # (1,2), (2,3), (3,4)
```

`itertools` is part of the stdlib; reach for it before rolling your own.

---

## `yield from` for Delegation

When one generator wraps another, `yield from` is shorter than re-yielding:

```python
def all_users(db):
    yield from db.fetch_admins()
    yield from db.fetch_editors()
    yield from db.fetch_viewers()
```

Equivalent to:

```python
def all_users(db):
    for u in db.fetch_admins(): yield u
    for u in db.fetch_editors(): yield u
    for u in db.fetch_viewers(): yield u
```

`yield from` also handles the receive-from-send protocol when used with
coroutines (historical use; modern async uses `async/await`).

---

## Generators Run Once

A generator object exhausts on iteration. Iterate twice and the second pass
yields nothing.

```python
gen = (x * 2 for x in range(3))
list(gen)        # [0, 2, 4]
list(gen)        # [] — exhausted
```

If you need to iterate multiple times, materialize into a list — or use
`itertools.tee` to branch.

---

## Cleanup with `finally`

A generator's `finally` block runs when the generator is closed (by garbage
collection or `gen.close()`):

```python
def stream_lines(path):
    f = open(path)
    try:
        for line in f:
            yield line.rstrip()
    finally:
        f.close()
```

Or, simpler, use a `with` block:

```python
def stream_lines(path):
    with open(path) as f:
        for line in f:
            yield line.rstrip()
```

The `with` block handles cleanup on generator close, exception, or normal
exhaustion.

---

## Async Generators

`async def` + `yield` = async generator. Consume with `async for`:

```python
async def fetch_pages(url):
    next_url: str | None = url
    while next_url:
        page = await fetch_json(next_url)
        for item in page["items"]:
            yield item
        next_url = page.get("next_url")

async for item in fetch_pages("/api/items"):
    await process(item)
```

Async generators can have `finally` blocks too, but make sure consumers
explicitly close them (`await gen.aclose()`) or use `async for`, which closes
on `break` and normal exhaustion.

---

## `iter()` and `next()` for Custom Iteration

```python
it = iter(items)
first = next(it)
second = next(it)
remaining = list(it)
```

`next(it, default)` returns `default` instead of raising `StopIteration`. The
two-arg form is the easy way to express "give me the first match or None":

```python
first_admin = next((u for u in users if u.is_admin), None)
```

---

## Custom Iterators

For most cases, write a generator function. For genuinely stateful iteration
(custom restart, peek, look-ahead), implement `__iter__` and `__next__`:

```python
class PeekableIterator:
    def __init__(self, source):
        self._source = iter(source)
        self._peeked = None

    def __iter__(self):
        return self

    def __next__(self):
        if self._peeked is not None:
            value, self._peeked = self._peeked, None
            return value
        return next(self._source)

    def peek(self):
        if self._peeked is None:
            try:
                self._peeked = next(self._source)
            except StopIteration:
                return None
        return self._peeked
```

99 % of iteration needs are met by generators; reach for a class only when
the protocol genuinely benefits.

---

## Don't `list(generator)` Then Loop

```python
# Bad — materializes a million items
for item in list(big_generator()):
    process(item)

# Good
for item in big_generator():
    process(item)
```

The only reason to `list()` a generator is if you need to iterate multiple
times, count without consuming, or index in.

---

## Quick Reference

| Need | Reach for |
|---|---|
| Lazy iteration | Generator function |
| Inline lazy expression | Generator expression `(...)` |
| Concat / flatten / pair | `itertools.chain`, `pairwise` |
| Group adjacent | `itertools.groupby` (sort first if needed) |
| First match or None | `next(gen, None)` |
| Delegate to inner | `yield from` |
| Cleanup on close | `with` inside the generator |
| Async source | `async def` + `yield` + `async for` |

## Related Skills

- **Control flow**: [py-control-flow](../py-control-flow/SKILL.md) for comprehensions vs loops.
- **Data structures**: [py-data-structures](../py-data-structures/SKILL.md) for materialized containers.
- **Performance**: [py-performance](../py-performance/SKILL.md) for memory-bounded streaming.
- **Async**: [py-async](../py-async/SKILL.md) for async generators and `async for`.
- **Functions**: [py-functions](../py-functions/SKILL.md) for `yield` semantics in function signatures.
