---
name: py-classes
description: Use when designing or reviewing Python classes — choosing between `@dataclass`, regular classes, ABCs, `Protocol`, properties, classmethod vs staticmethod, `__slots__`, dunder methods, inheritance vs composition, mixins. Also use when refactoring inheritance hierarchies or replacing a class with a function.
license: Apache-2.0
metadata:
  sources: "Python data model, PEP 557 (dataclass), PEP 544 (Protocol), Fluent Python"
---

# Python Classes

## Class or Function?

Reach for a class when:

- The object has **identity** callers depend on (a service, a connection).
- The state and behavior are tightly coupled and used together.
- Polymorphism (multiple implementations of the same interface) is the point.

Reach for a function (or module) when:

- It's pure data — use `@dataclass` or `TypedDict`.
- It's stateless behavior — use a function or a module of functions.
- The "class" has one method — that's a function with a fancy hat.

```python
# Bad — stateless utility class
class StringUtils:
    @staticmethod
    def to_kebab(s): ...
    @staticmethod
    def to_camel(s): ...

# Good — module of functions
def to_kebab(s: str) -> str: ...
def to_camel(s: str) -> str: ...
```

---

## `@dataclass` First

For value-like records, `@dataclass` is the default:

```python
from dataclasses import dataclass

@dataclass(frozen=True, slots=True)
class User:
    id: str
    email: str
    is_admin: bool = False
```

`frozen=True` makes it immutable (raises on assignment). `slots=True` (3.10+)
prevents attribute typos and cuts memory.

Add methods normally:

```python
@dataclass(frozen=True, slots=True)
class User:
    id: str
    email: str

    def display(self) -> str:
        return f"{self.email} ({self.id})"
```

Default factories for mutable defaults:

```python
from dataclasses import field

@dataclass
class Cart:
    items: list[Item] = field(default_factory=list)
```

---

## `__slots__` Cuts Memory

For classes you'll instantiate a lot (records, events), `__slots__` (or
`slots=True` on dataclass) replaces `__dict__` with a fixed layout — less
memory, faster attribute access, no accidental attribute creation:

```python
class Point:
    __slots__ = ("x", "y")

    def __init__(self, x: float, y: float) -> None:
        self.x = x
        self.y = y

# p.z = 0  # AttributeError
```

Don't use `__slots__` on classes you'll subclass without thinking through the
slot inheritance rules; check the docs.

---

## `classmethod` vs `staticmethod` vs Module Function

| Decorator | Receives | When |
|---|---|---|
| (none) — regular method | `self` | Most methods |
| `@classmethod` | `cls` | Alternate constructors, polymorphic class access |
| `@staticmethod` | nothing | Closely related helper that doesn't need `cls` |
| module function | nothing | Truly independent — preferred over `@staticmethod` |

```python
@dataclass(frozen=True)
class User:
    id: str
    email: str

    @classmethod
    def from_row(cls, row) -> "User":
        return cls(id=row["id"], email=row["email"])

    @classmethod
    def empty(cls) -> "User":
        return cls(id="", email="")
```

`@staticmethod` is rarely the right answer. If the method doesn't use `self`
or `cls`, it usually belongs as a module-level function. Use `@staticmethod`
only when grouping under the class name is genuinely helpful.

---

## Properties: For Computed Values, Not Field Wrappers

```python
@dataclass
class Cart:
    items: list[Item]

    @property
    def total(self) -> float:
        return sum(item.price for item in self.items)
```

Don't wrap a plain field in a `@property` getter/setter pair that just reads
and writes the same value — expose the field directly.

```python
# Bad — no-op property
class User:
    def __init__(self, name):
        self._name = name

    @property
    def name(self):
        return self._name

    @name.setter
    def name(self, v):
        self._name = v

# Good
@dataclass
class User:
    name: str
```

Properties should be cheap (no I/O, no throw). Anything heavier is a method:
`get_x()`, `load_x()`.

---

## Composition Over Inheritance

A two-level `class A(B)` is sometimes useful. A three-level chain almost
never is — extract shared behavior and inject it.

```python
# Bad
class Animal: ...
class Mammal(Animal): ...
class Dog(Mammal): ...

# Good
@dataclass
class Dog:
    walker: "Walker"
    logger: Logger
    def walk(self): self.walker.walk()
```

Prefer `Protocol` over inheritance for shared API contracts:

```python
from typing import Protocol

class Walker(Protocol):
    def walk(self) -> None: ...
```

Any class with a `walk()` method satisfies the protocol — no inheritance,
no abstract base class, no ceremony.

---

## ABCs: When `Protocol` Doesn't Fit

Use `abc.ABC` and `@abstractmethod` when you need:

- Shared implementation in the base class that subclasses extend.
- Runtime enforcement that subclasses implement abstract methods.

```python
from abc import ABC, abstractmethod

class Storage(ABC):
    def save_with_audit(self, obj):
        self.audit(obj)
        self.save(obj)

    def audit(self, obj):
        log.info({"action": "save", "id": obj.id}, "audit")

    @abstractmethod
    def save(self, obj) -> None: ...
```

If the base has no concrete code — just abstract methods — switch to
`Protocol` and drop the ABC. ABCs are for *partial implementations*.

---

## Dunder Methods

Implement what your class genuinely supports. Don't add `__repr__` if the
default is fine; don't add `__eq__` if dataclass gives it for free.

The high-value ones:

| Dunder | What |
|---|---|
| `__repr__` | Debugging-friendly representation (always for non-trivial classes) |
| `__eq__` | Value equality |
| `__hash__` | Hashability (required for set/dict keys) |
| `__iter__` | Iteration |
| `__enter__` / `__exit__` | `with` statement support |
| `__aenter__` / `__aexit__` | `async with` support |
| `__call__` | Make instance callable |
| `__lt__` | Comparison (combine with `functools.total_ordering`) |

If you implement `__eq__`, also implement `__hash__` (or set it to `None` to
explicitly forbid hashing). Dataclasses get both based on `frozen` and `eq`
flags.

---

## Method Resolution Order (MRO)

Python uses C3 linearization. Multiple inheritance is legitimate but tricky.
Stick to:

- Single inheritance + composition for most cases.
- Mixins for genuine cross-cutting (`LoggingMixin`, `TimestampMixin`).
- Avoid the "diamond" — class C inheriting from two classes that share a
  base.

If you find yourself reading the MRO to understand which method runs, the
hierarchy is too complex.

---

## Method Visibility

`_method` is internal convention. `__method` (no trailing) triggers name
mangling — rarely the right call. See [py-naming](../py-naming/SKILL.md).

Don't write Java-style `public/protected/private`. Python's convention is the
underscore prefix; trust the convention.

---

## `__init_subclass__` and Metaclasses

Reach for `__init_subclass__` to customize subclass creation (registering,
validating). Reach for a metaclass only when `__init_subclass__` doesn't
suffice and you've understood the consequences.

```python
class Plugin:
    registry: dict[str, type["Plugin"]] = {}

    def __init_subclass__(cls, *, name: str, **kwargs):
        super().__init_subclass__(**kwargs)
        cls.registry[name] = cls
```

Most code that uses metaclasses can be rewritten with decorators or
`__init_subclass__` more clearly.

---

## Equality and `__hash__`

```python
@dataclass(frozen=True)  # frozen → hashable
class Point:
    x: float
    y: float

s = {Point(1, 2), Point(1, 2)}   # one element, by-value equality
```

For non-dataclass classes, implement `__eq__` and `__hash__` together. Two
objects equal under `__eq__` MUST hash equal. Breaking this invariant breaks
dicts and sets in subtle ways.

---

## Quick Reference

| Question | Default |
|---|---|
| Pure data | `@dataclass(frozen=True, slots=True)` |
| Tuple-shaped record | `NamedTuple` |
| Interface contract | `Protocol` |
| Partial implementation | `ABC` |
| Private | `_leading_underscore` |
| Computed field | `@property` |
| Constant memory class | `__slots__` |
| Alternate constructor | `@classmethod` |
| Truly independent helper | module function |

## Related Skills

- **Style core**: [py-style-core](../py-style-core/SKILL.md) for the broader baseline.
- **Naming**: [py-naming](../py-naming/SKILL.md) for member naming.
- **Typing**: [py-typing](../py-typing/SKILL.md) for `Protocol`, `Generic`, type vars.
- **Data structures**: [py-data-structures](../py-data-structures/SKILL.md) for `@dataclass` vs `TypedDict` vs `NamedTuple`.
- **Functions**: [py-functions](../py-functions/SKILL.md) for method signatures.
- **Documentation**: [py-documentation](../py-documentation/SKILL.md) for class docstrings.
