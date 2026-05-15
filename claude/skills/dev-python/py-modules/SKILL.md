---
name: py-modules
description: Use when organizing Python modules and packages — designing the package layout, choosing between regular and namespace packages, ordering imports, using `__init__.py` for public API re-exports, configuring `pyproject.toml` for distribution, and handling relative vs absolute imports. Also use when migrating a legacy layout to `src/`.
license: Apache-2.0
metadata:
  sources: "PEP 8, PEP 328, PEP 420, Python Packaging User Guide"
---

# Python Modules and Imports

## Package Layout: Use `src/`

For library and service projects, put your package under `src/`:

```
my-project/
├── pyproject.toml
├── README.md
├── src/
│   └── myapp/
│       ├── __init__.py
│       ├── user.py
│       └── http/
│           ├── __init__.py
│           └── routes.py
└── tests/
    ├── conftest.py
    └── test_user.py
```

Why: `src/` prevents `python -c "import myapp"` from accidentally importing the
working directory instead of the installed package. Editable installs
(`pip install -e .`) work the same way as production installs. The bug-class
"works on my machine because I was importing the repo, not the package" is
eliminated.

---

## Import Order

Group imports in three blocks, separated by a blank line:

1. Standard library.
2. Third-party packages.
3. First-party (your project).

Within each group, sort alphabetically. Use Ruff's `isort` integration
(`ruff check --select I`) or `isort` directly.

```python
from __future__ import annotations

import json
import os
from pathlib import Path

import httpx
from pydantic import BaseModel

from myapp.config import settings
from myapp.user import User
```

`from __future__ import annotations` goes first (it has to). On Python 3.12+,
postponed annotations are no longer the eventual default — but `from __future__
import annotations` is still useful for forward references and minor speed.

---

## Absolute Imports Over Relative

Prefer absolute imports. They survive moves, refactors, and grep.

```python
# Good
from myapp.user.repository import UserRepository

# Acceptable for sibling within the same package
from .models import User

# Bad — sibling with multiple parents
from ...config import settings
```

Relative imports are useful for **intra-package** references where you really
do want the import to track if the package is renamed. Once you reach `..` or
deeper, switch to absolute.

---

## `__init__.py`: The Package's Public API

`__init__.py` defines what `from package import ...` exposes. Use it to curate:

```python
# myapp/user/__init__.py
"""User domain — models, repository, service."""
from myapp.user.models import User, UserId
from myapp.user.repository import UserRepository

__all__ = ["User", "UserId", "UserRepository"]
```

`__all__` defines what `from myapp.user import *` returns. Even if your project
doesn't use `*`-imports, declaring `__all__` documents intent and helps tools
(IDE auto-import, Sphinx) pick the public surface.

Don't put real logic in `__init__.py`. It runs on every import of the package
and complicates testing.

---

## Regular vs Namespace Packages

A **regular package** has an `__init__.py`. A **namespace package** (PEP 420)
does not — its content is split across multiple directories, useful for plugin
systems (`mycorp.plugins.foo`, `mycorp.plugins.bar`).

For application code, use regular packages. For projects that publish under a
shared top-level name (a corporate "namespace"), namespace packages are
correct.

---

## `pyproject.toml`

Modern Python projects use `pyproject.toml` as the single source of truth. The
standard build system fields:

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "myapp"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
    "httpx>=0.27",
    "pydantic>=2.7",
]

[project.optional-dependencies]
dev = ["pytest>=8", "ruff>=0.5", "mypy>=1.10"]

[tool.hatch.build.targets.wheel]
packages = ["src/myapp"]
```

The build backend (`hatchling`, `setuptools`, `flit`, `poetry-core`) is a
project choice; all of them read `pyproject.toml`.

---

## Dependency Management

Two contenders for modern Python:

| Tool | When |
|---|---|
| `uv` | Default for new projects — fast, lockfile-native, single binary. |
| `Poetry` | Established projects; integrated dependency resolver. |
| `pip` + `pip-tools` + `requirements.txt` | Minimum-deps environments, single-purpose CLIs. |

For new projects:

```bash
uv init my-project
uv add httpx pydantic
uv add --dev pytest ruff mypy
uv lock
uv sync
```

`uv.lock` (or `poetry.lock`) is committed; `requirements.txt` is generated
from it when needed.

---

## Don't `from foo import *`

```python
# Bad — pollutes the namespace, defeats grep
from numpy import *

# Good
import numpy as np
arr = np.array([1, 2, 3])

# Good
from numpy import array
arr = array([1, 2, 3])
```

The only common, sanctioned exception is `from tkinter import *` in toy
examples, and even there it's avoidable.

---

## Re-Exports

When `__init__.py` re-exports symbols, declare them in `__all__` and consider
using explicit `as` aliases (Mypy's `--no-implicit-reexport`):

```python
# myapp/__init__.py
from myapp.user.models import User as User       # explicit re-export
from myapp.user.repository import UserRepository as UserRepository

__all__ = ["User", "UserRepository"]
```

Without `as Same`, strict Mypy may warn that the symbol isn't a re-export.

---

## Circular Imports

When `a.py` imports from `b.py` and `b.py` imports from `a.py`, the second
import resolves to a half-initialized module and breaks.

Fixes (in preference order):

1. **Move shared code** into a third module both can import.
2. **Local import** inside the function that needs it (deferred).
3. **`TYPE_CHECKING`** guard for type-only imports:

```python
from __future__ import annotations
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from myapp.user import User

def serialize(u: "User") -> dict: ...
```

`TYPE_CHECKING` is `False` at runtime, so the import never happens during
execution — type checkers still see it.

---

## Script vs Module Execution

Run modules with `python -m`:

```bash
python -m myapp.cli serve
```

Not:

```bash
python src/myapp/cli.py serve   # fragile — depends on sys.path
```

`-m` ensures the package is properly resolved and relative imports work.

---

## Quick Reference

| Question | Default |
|---|---|
| Layout | `src/myapp/` |
| Import style | Absolute |
| Sibling intra-package | Single-dot relative |
| `__init__.py` content | Re-exports + `__all__` |
| Build / deps | `pyproject.toml` + `uv` |
| Avoid | `from foo import *`, deep relative imports |
| Circular | Restructure or `TYPE_CHECKING` |
| Run module | `python -m package.module` |

## Related Skills

- **Style core**: [py-style-core](../py-style-core/SKILL.md) for import block ordering inside files.
- **Naming**: [py-naming](../py-naming/SKILL.md) for module/package names.
- **Typing**: [py-typing](../py-typing/SKILL.md) for `from __future__ import annotations` and `TYPE_CHECKING`.
- **Config**: [py-config](../py-config/SKILL.md) for `pyproject.toml` tool sections.
- **Linting**: [py-linting](../py-linting/SKILL.md) for `ruff check --select I` (isort).
