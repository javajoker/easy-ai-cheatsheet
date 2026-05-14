# Git Workflow

> Default branching and commit conventions. A project can override with its
> own `projects/<name>/git-workflow.md` if it follows a different model
> (trunk-based, GitFlow, release branches, etc.).

## Default branch model

- `main` — **release branch**. Always deployable.
- `feature/<topic>` — new functionality, branched from `main`.
- `bugfix/<topic>` — bug fix, branched from `main`.
- `chore/<topic>` — non-functional work (dependency bumps, CI changes,
  documentation), branched from `main`.

**Never develop directly on `main`.** Open a branch.

## Commit format

```
<type>(<scope>): <subject>
```

Types:

- `feat` — new functionality.
- `fix` — bug fix.
- `docs` — documentation only.
- `refactor` — code restructure without behavioural change.
- `test` — tests only.
- `perf` — performance improvement.
- `chore` — build, dependencies, tooling.
- `revert` — reverts a previous commit.

Scope is the package, module, or area name. Subject is imperative, present
tense, no trailing period.

Examples:

```
feat(redis): support pipeline batching
fix(breaker): correct sliding-window edge counting
docs(http-server): document gRPC interceptor usage
test(errors): cover TryCatchChain boundary cases
chore(deps): bump zap to 1.27
```

For projects using Conventional Commits with a footer for breaking changes:

```
refactor(api)!: rename Client.Get to Client.Fetch

BREAKING CHANGE: callers must update to the new method name.
```

## Workflow

1. From `main`, open a branch: `git checkout -b feature/<topic>`.
2. Develop in small commits — each commit a coherent change.
3. Push: `git push origin feature/<topic>`.
4. Open a Pull Request targeting `main`.
5. Address review feedback in new commits (do not amend or force-push during review).
6. Merge after approval.

## After merge

- Delete the merged branch.
- Tag releases with semantic versions when applicable:
  - `v1.0.0` — major (breaking change).
  - `v1.1.0` — minor (new functionality, backwards compatible).
  - `v1.1.1` — patch (bug fix).

## Pre-commit hooks

If the project has pre-commit hooks (linting, formatting, type-checking, test
subset), let them run. **Never bypass with `--no-verify`** unless the user
explicitly asks for it. If a hook fails, fix the underlying issue.

## Destructive operations

These need explicit user authorization, not standing permission:

- `git push --force` and `git push --force-with-lease`.
- `git reset --hard`.
- `git branch -D` on branches with unmerged commits.
- `git clean -fd`.
- Rewriting history on a published branch.

`--force-with-lease` is safer than `--force` but still requires authorization.

---

**Version**: 2.0.0
**Updated**: 2026-05-13
