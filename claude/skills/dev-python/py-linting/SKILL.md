---
name: py-linting
description: Use when setting up, tuning, or troubleshooting Python linters and formatters — Ruff (preferred), Black, isort, Mypy, Pyright, Bandit, pre-commit hooks, CI integration, or migrating from `flake8` + `pylint` to Ruff. Also use when reviewing lint suppressions.
license: Apache-2.0
metadata:
  sources: "Ruff docs, Black docs, Mypy docs, Pyright docs, pre-commit docs"
allowed-tools: Bash(bash:*)
---

# Python Linting

## Available Scripts and Assets

- **`assets/ruff.toml`** — Canonical Ruff configuration with a curated rule set (E, W, F, I, B, UP, N, S, SIM, RUF, ASYNC, TID, ARG, PTH, PIE, TRY) and Google-style docstring convention. Drop in the repo root, or merge under `[tool.ruff]` in `pyproject.toml`.
- **`assets/pre-commit-config.yaml`** — Matching `.pre-commit-config.yaml` with ruff, ruff-format, and mypy hooks.
- **`scripts/setup-lint.sh`** — Installs ruff, mypy, and pre-commit; copies both configs into the project root; auto-detects uv / Poetry / pip. Supports `--force`, `--no-install`. Run `bash scripts/setup-lint.sh --help`.

## One Linter, One Formatter

For new projects, the canonical stack is:

- **Ruff** — linter (replaces `flake8`, `pylint`, `isort`, `pyupgrade`, and
  many small plugins).
- **Ruff format** (or Black) — formatter.
- **Mypy or Pyright** — type checker (pick one).

This stack is 10–100× faster than the previous generation and configurable
through `pyproject.toml`. Don't run `flake8` + `pylint` + `isort` + `black`
separately on a greenfield project.

```toml
# pyproject.toml
[tool.ruff]
line-length = 100
target-version = "py312"
src = ["src", "tests"]

[tool.ruff.lint]
select = [
    "E", "W",       # pycodestyle
    "F",            # pyflakes
    "I",            # isort
    "B",            # flake8-bugbear
    "C4",           # flake8-comprehensions
    "UP",           # pyupgrade
    "N",            # pep8-naming
    "S",            # flake8-bandit (security)
    "SIM",          # flake8-simplify
    "RUF",          # ruff-specific
    "ASYNC",        # flake8-async
    "TID",          # flake8-tidy-imports
    "ARG",          # unused arguments
]
ignore = [
    "E501",         # line length handled by formatter
]

[tool.ruff.lint.per-file-ignores]
"tests/**" = ["S101"]   # allow assert in tests

[tool.ruff.format]
quote-style = "double"
```

---

## Ruff Rule Sets

Ruff bundles a large catalog. Start with the set above and add as the
project grows:

| Set | What it catches |
|---|---|
| `E`, `W` | pycodestyle errors and warnings |
| `F` | undefined names, unused imports |
| `I` | import order (isort) |
| `B` | bugbear — common bugs (mutable default, `dict()` over `{}`) |
| `UP` | pyupgrade — modernize syntax (Python 3.x features) |
| `N` | PEP 8 naming |
| `S` | bandit — security smells |
| `SIM` | simplify — refactor opportunities |
| `ASYNC` | asyncio anti-patterns |
| `C4` | comprehension improvements |
| `RUF` | Ruff-specific |
| `D` | pydocstyle — opt-in if you enforce docstrings |
| `ANN` | annotation completeness — strict typing |
| `PL` | pylint subset (slow; opt-in) |

Don't enable everything — the team will hate it. Start strict, relax as you
find rules that don't fit the project.

---

## Type Checker: Pick One

| Checker | When |
|---|---|
| **Pyright** | Fast, default in Pylance (VS Code) |
| **Mypy** | Established, mature, plugin ecosystem (pydantic-mypy, sqlalchemy) |

Both are fine; don't run both. Mypy is friendlier for projects that need
plugins; Pyright is faster and stricter by default.

```toml
[tool.mypy]
python_version = "3.12"
strict = true
warn_unused_ignores = true
warn_unreachable = true
disallow_untyped_defs = true
no_implicit_reexport = true
plugins = ["pydantic.mypy"]
```

```toml
[tool.pyright]
pythonVersion = "3.12"
typeCheckingMode = "strict"
reportMissingTypeStubs = "error"
```

Run the type checker separately from Ruff in CI — they complement each
other, but a type error is a different bug than a style violation.

---

## Pre-Commit Hooks

`pre-commit` runs the linters on changed files before each commit — fast
enough to use on every commit.

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.5.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.10.0
    hooks:
      - id: mypy
        additional_dependencies: ["pydantic"]
```

```bash
pre-commit install        # set up the git hook
pre-commit run --all      # run on the whole repo
```

Don't block commits on a full project lint — slow hooks get skipped with
`--no-verify`. Aim for under 5 seconds on a typical change.

---

## CI Integration

```yaml
# .github/workflows/ci.yml
- run: pip install -e ".[dev]"
- run: ruff check .
- run: ruff format --check .
- run: mypy src/
- run: pytest --cov=src
- run: pip-audit
```

Each check is a separate step so failures are clearly attributed.
`pip-audit` for known vulnerabilities; see [py-security](../py-security/SKILL.md).

---

## Suppressing a Rule

Every `# noqa` comment should name the rule and ideally give a reason:

```python
# Good
import unused_for_side_effect  # noqa: F401 -- registers a signal handler
x: Any = legacy_call()  # noqa: ANN401 -- third-party returns Any

# Bad
import unused  # noqa
```

`# type: ignore` for the type checker should also be specific:

```python
result = unknown_lib.call()  # type: ignore[no-untyped-call]
```

Open suppressions accumulate technical debt. Periodically:

```bash
grep -rn 'noqa\|type: ignore' src/ | wc -l
```

Trend it down.

---

## Auto-Fix

Ruff fixes many violations automatically:

```bash
ruff check --fix
ruff format
```

In CI, *check* — don't auto-fix in CI. Auto-fix runs locally or in
pre-commit, where the author reviews the change before committing.

---

## Naming Convention Rule (`N`)

Ruff's `N` rules enforce PEP 8 naming:

- `N801` Class name should be `CapWords`.
- `N802` Function name should be `lower_case`.
- `N803` Argument name should be `lower_case`.
- `N806` Variable should be `lower_case`.
- `N818` Exception name should end with `Error`.

Don't tune the rule incrementally — get the team to agree once, then commit
the config.

---

## Security Linter (`S` / Bandit)

The `S` set covers common security smells:

- `S101` `assert` in production code (stripped under `-O`).
- `S301-S312` Pickle / yaml.load / etc.
- `S602-S608` `subprocess` with `shell=True`.
- `S105-S107` Hardcoded passwords / secrets.

Enable in CI. Suppressions need a reason — these are not stylistic
preferences.

---

## Migrating from `flake8` + `pylint` + `isort` + `black`

`ruff check --select ALL --fix` is the lazy upgrade path. Be careful — many
rules contradict each other; some auto-fixes change behaviour. Migrate
incrementally:

1. Install Ruff alongside the existing tools.
2. Enable the equivalent rule sets (`E`, `W`, `F`, `I`) — same rules, same
   results.
3. Migrate config from `setup.cfg` / `.flake8` / `.pylintrc` to
   `pyproject.toml`.
4. Run `ruff check` in CI; remove old tools once green.
5. Add new rule sets (`B`, `UP`, `SIM`, `S`) incrementally.

---

## Editor Integration

VS Code: install **Ruff** and **Pylance** extensions. Set `editor.formatOnSave`
and `editor.codeActionsOnSave: { "source.fixAll": "explicit" }`.

PyCharm: Ruff plugin from the marketplace.

Editor lint feedback closes the loop — bugs caught while typing don't reach
the PR.

---

## Quick Reference

| Tool | Role |
|---|---|
| Ruff (lint) | Style + many bug catches |
| Ruff format (or Black) | Formatting |
| Mypy or Pyright | Type checking |
| pre-commit | Local enforcement |
| pip-audit / safety | Dependency vulnerabilities |
| Editor extension | Real-time feedback |

## Related Skills

- **Style core**: [py-style-core](../py-style-core/SKILL.md) for the principles Ruff enforces.
- **Naming**: [py-naming](../py-naming/SKILL.md) for what the `N` rules enforce.
- **Modules**: [py-modules](../py-modules/SKILL.md) for `pyproject.toml` layout.
- **Typing**: [py-typing](../py-typing/SKILL.md) for type-checker config.
- **Security**: [py-security](../py-security/SKILL.md) for the `S` rules in detail.
- **Code review**: [py-code-review](../py-code-review/SKILL.md) for when to push back on suppressions.
