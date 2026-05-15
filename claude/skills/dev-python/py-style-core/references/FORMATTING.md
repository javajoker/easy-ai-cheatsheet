# Formatting Reference

## Tooling Decision

Run a formatter. Two canonical choices:

- **Ruff format** (preferred for new projects) — Black-compatible output;
  shares cache with `ruff check`; very fast.
- **Black** — established and battle-tested.

Don't argue about quote style or trailing commas in code review — the
formatter decides.

```toml
# pyproject.toml
[tool.ruff]
line-length = 100
target-version = "py312"

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
line-ending = "lf"
```

CI:

```bash
ruff format --check .
ruff check .
```

Run the formatter on save in your editor. Pre-commit hook on file
patterns (see [py-linting](../py-linting/SKILL.md)).

## Line Length

| Choice | When |
|---|---|
| 88 | Black / Ruff default |
| 100 | Common compromise for new projects |
| 120 | Older codebases, wide monitors |

Pick once. Refactor for readability when a line wants to be longer —
extract a local with a meaningful name; don't backslash-continue.

```python
# Bad — backslash continuation
result = some_function(very_long_argument_name, another_argument, \
                       more_args, even_more)

# Good — let the formatter wrap, or pull into a tuple/local
args = (very_long_argument_name, another_argument, more_args, even_more)
result = some_function(*args)
```

## Indentation

4 spaces. Always. No tabs anywhere except in `Makefile`.

For continuation lines, 4 additional spaces (one indent level) or align
with opening delimiter:

```python
# Good — additional indent
def long_function_name(
    var_one: int,
    var_two: int,
) -> int:
    return var_one + var_two

# Good — aligned with delimiter
return some_function(arg_one,
                     arg_two,
                     arg_three)
```

Ruff/Black picks one consistently; don't mix.

## Quote Style

| Choice | When |
|---|---|
| Double | Ruff / Black default |
| Single | PEP 8 doesn't require either |

Set `quote-style = "double"` (or `"single"`) and don't think about it
again. Use the other style to avoid escaping when the string contains the
chosen quote.

```python
# Good
msg = "she said \"hello\""
msg = 'she said "hello"'   # cleaner when double is chosen project-wide
```

## Trailing Commas

Black/Ruff add trailing commas in multi-line containers and function
signatures. They:

- Make diffs cleaner when adding new last element.
- Don't affect runtime.

```python
def f(
    a: int,
    b: int,
    c: int,
):
    return a + b + c

items = [
    "alice",
    "bob",
    "charlie",
]
```

## Blank Lines

| Place | Lines |
|---|---|
| Between top-level defs | 2 |
| Between methods | 1 |
| Inside function (logical sections) | 1, sparingly |
| End of file | 1 |

Two blank lines between top-level functions or classes is the canonical
"a fresh block starts here" signal.

## Imports

```python
# Standard library
import json
import os
from pathlib import Path

# Third-party
import httpx
from pydantic import BaseModel

# First-party
from myapp.config import settings
from myapp.user import User
```

Three blocks, blank line between. Sort within blocks. Use Ruff's `I`
rules (isort-compatible) to enforce.

```bash
ruff check --select I --fix .
```

## CI Check

```yaml
- name: Format check
  run: ruff format --check .

- name: Lint
  run: ruff check .
```

Don't auto-format in CI — that's what `pre-commit` is for, locally. CI
should *fail* on formatting violations so the bad commit doesn't land
silently.

## Editor Config

`.editorconfig` covers what the Python formatter doesn't (newlines,
charset, trim trailing whitespace):

```
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.py]
indent_style = space
indent_size = 4

[Makefile]
indent_style = tab
```

## Migrating Between Formatters

Switching Black → Ruff format: the output is byte-identical for the
overwhelming majority of code. Run once across the repo as a single
commit; future diffs stay clean.

Switching from autopep8 / yapf to Black or Ruff format: expect a big
one-time reformat. Land it in isolation; don't mix with logic changes.
