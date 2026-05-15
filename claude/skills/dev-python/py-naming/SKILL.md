---
name: py-naming
description: Use when naming variables, functions, classes, modules, packages, constants, type variables, or private members in Python. Also use when reviewing identifier names, applying single vs double underscore conventions, choosing exception class names, or naming protocol/abstract base classes.
license: Apache-2.0
metadata:
  sources: "PEP 8, Google Python Style Guide, typing module conventions"
allowed-tools: Bash(bash:*)
---

# Python Naming

## Available Scripts

- **`scripts/check-naming.sh`** — Scans Python files for naming-convention violations: classes in snake_case/camelCase, functions in PascalCase/camelCase, Hungarian-style prefixes, and exception classes not ending in `Error`. Run `bash scripts/check-naming.sh --help` for options. For stronger enforcement, configure Ruff's `N` rule set (see [py-linting](../py-linting/SKILL.md)).

## Identifier Cases (Canonical Table)

| Kind | Case | Example |
|---|---|---|
| Variables, functions, methods | `snake_case` | `user_count`, `get_user` |
| Module-level constants | `UPPER_SNAKE_CASE` | `DEFAULT_TIMEOUT_SECONDS` |
| Classes, type aliases, named tuples | `PascalCase` | `UserRepository`, `Order` |
| Type variables | `PascalCase`, often short | `T`, `K`, `User` |
| Protocols and ABCs | `PascalCase` (no `I` prefix) | `Sized`, `UserRepo` |
| Exception classes | `PascalCase` ending in `Error` | `NotFoundError`, `ConfigError` |
| Modules, packages | `lowercase_with_underscores` | `user_service`, `db_pool` |
| Private (module / class internal) | `_leading_underscore` | `_helper`, `_cache` |
| Mangled (subclass collision avoidance) | `__double_leading` | `__internal` |
| Dunder (Python protocol) | `__name__` | `__init__`, `__repr__` |

Stick to the project's case convention. PEP 8 is the default; many older
projects use `camelCase` for variables — match what's already there.

---

## Single Underscore: Convention, Not Enforcement

`_name` is a convention for "internal" or "not part of the public API". Tools
respect it (Sphinx auto-doc, `from module import *`), Python itself does not
restrict access.

```python
class UserService:
    def __init__(self):
        self._cache = {}            # internal; subclasses may use it

    def _normalize(self, email):     # internal helper
        return email.lower()

    def get_user(self, id):          # public
        ...
```

Use it sparingly. A class with 20 methods all starting with `_` is suspect —
either they're public (drop the underscore), or the class is doing too much.

---

## Double Underscore: Name Mangling

`__name` (no trailing underscores) triggers name mangling. The attribute is
stored as `_ClassName__name`. Use only when you need to avoid collision with
subclasses, which is rare. Most code that uses `__` should be using single `_`.

```python
class Base:
    def __init__(self):
        self.__private = 1     # stored as _Base__private

class Child(Base):
    def __init__(self):
        super().__init__()
        self.__private = 2     # stored as _Child__private — different attr
```

`__init__`, `__repr__`, etc. are **dunders** — language protocols, not the same
thing. They have trailing underscores too.

---

## No Hungarian, No Type-Encoding

```python
# Bad
str_name = "alice"
list_users = []
dict_config = {}

# Good
name = "alice"
users = []
config = {}
```

Type hints carry the type. The name carries the meaning.

---

## Functions: Verbs

| Verb stem | When |
|---|---|
| `get_` / `fetch_` | Read |
| `set_` / `update_` | Mutate |
| `create_` / `make_` / `build_` | Construct |
| `delete_` / `remove_` | Destroy |
| `is_` / `has_` / `can_` | Boolean predicate |
| `to_` | Convert (`to_dict`, `to_json`) |
| `from_` | Construct (`User.from_row`) |

```python
def is_admin(user) -> bool: ...
def has_access(user, resource) -> bool: ...
def to_dict(self) -> dict: ...
@classmethod
def from_row(cls, row) -> "User": ...
```

A function returning a `bool` should read as a question. Avoid negated
predicates (`is_not_active`) — flip the name (`is_inactive`).

---

## Classes: Noun

A class is a thing, so its name is a noun.

```python
class UserRepository: ...       # good
class GetUser: ...              # bad — that's a function
class UserGetter: ...           # bad — same problem
```

If the "class" exists only to hold related functions, it's a module. If it
has one method, it's a function.

---

## Don't Repeat the Module

Module-qualified usage shouldn't stutter:

```python
# Bad — package is "user", file is "user_repository.py"
# user/user_repository.py
class UserUserRepository: ...

# Good
# user/repository.py
class Repository: ...
# called as user.Repository

# Or
# user/user_repository.py
class UserRepository: ...
# called as user.user_repository.UserRepository (if you have several repos)
```

The most common pattern: have the package be `user/`, with files `__init__.py`,
`models.py`, `repository.py`, `service.py`. The class is `Repository`, used as
`from user.repository import Repository` or `from user import Repository` after
re-export in `__init__.py`.

---

## Constants

Module-level constants are `UPPER_SNAKE_CASE`. Anything looking like a constant
inside a function or a class method is just a local — keep it `lower_case`:

```python
DEFAULT_TIMEOUT = 30   # module constant

def fetch(url):
    timeout = DEFAULT_TIMEOUT   # local; not a constant
    ...
```

Avoid declaring "fake constants" — Python has no real `const`, so the
`UPPER_CASE` name is a *signal*, not enforcement. Use `typing.Final` for an
explicit annotation:

```python
from typing import Final
DEFAULT_TIMEOUT: Final = 30
```

---

## Exceptions

Subclass `Exception` (or a more specific one), name `XxxError`.

```python
class NotFoundError(Exception): ...
class ValidationError(Exception): ...
class ConflictError(Exception): ...
```

Don't end with `Exception` — that's already the base class name. `MyException`
reads strangely; `MyError` reads naturally. The exceptions in the stdlib follow
this (`ValueError`, `KeyError`, `RuntimeError`, except for `Exception` itself).

---

## Type Variables

Type variables are usually single capitals or short names. Use a descriptive
name when there are multiple in one signature.

```python
from typing import TypeVar

T = TypeVar("T")
K = TypeVar("K")
V = TypeVar("V")

UserT = TypeVar("UserT", bound="User")   # more descriptive when needed
```

Don't write `T_co`, `T_contra` unless you genuinely need covariance /
contravariance.

---

## Acronyms

Treat as words in the chosen case:

```python
# Good
class HttpClient: ...
class JsonParser: ...
def parse_url(s): ...

# Bad
class HTTPClient: ...
def parseURL(s): ...
```

PEP 8 allows `HTTPClient` for established acronyms; modern style trends toward
`HttpClient`. Pick one and apply consistently.

---

## File and Package Names

- Modules: `lowercase_with_underscores.py`.
- Packages: `lowercase` (no underscores when possible).
- Test files: `test_<module>.py` (pytest auto-discovery default).

```
src/
  myapp/
    __init__.py
    user.py
    user_repository.py
    config.py
  tests/
    test_user.py
    test_user_repository.py
```

---

## Quick Reference

| Question | Default |
|---|---|
| Variables, functions | `snake_case` |
| Classes, types | `PascalCase` |
| Constants | `UPPER_SNAKE_CASE` |
| Modules | `lower_snake_case` |
| Private | `_leading` |
| Boolean prefix | `is_` / `has_` / `can_` |
| Exception suffix | `Error` |

## Related Skills

- **Style core**: [py-style-core](../py-style-core/SKILL.md) for the broader style baseline.
- **Modules**: [py-modules](../py-modules/SKILL.md) for module/package layout.
- **Classes**: [py-classes](../py-classes/SKILL.md) for class member naming.
- **Typing**: [py-typing](../py-typing/SKILL.md) for type variable conventions.
- **Error handling**: [py-error-handling](../py-error-handling/SKILL.md) for exception class design.
- **Linting**: [py-linting](../py-linting/SKILL.md) for Ruff's naming rules.
