# Audit Template

Copy this template, fill in the requirements verbatim, audit per row.

```markdown
# Requirement Audit — <topic>

> Date: YYYY-MM-DD
> Auditor: Claude (session <id> or commit <sha>)
> Source of requirements: <user message / PRD / RFC id>

## Verdict

Summary: N PASS · M PARTIAL · K FAIL · L N/A (out of T total)

## Audit table

| # | Requirement | Status | Evidence |
|---|---|---|---|
| 1 | <verbatim requirement> | ✅ PASS | <pointer> |
| 2 | <verbatim requirement> | ⚠ PARTIAL | <pointer + one-line gap> |
| 3 | <verbatim requirement> | ❌ FAIL | <pointer + one-line reason> |

## Caveats

- <Things marked PASS but with conditions worth knowing>

## Follow-ups

- <What would upgrade PARTIAL items to PASS>

## Recommended next step

<One concrete suggestion>
```

## Worked example — the audit format in action

A small fictional audit of a five-point user request:

```markdown
# Requirement Audit — auth refactor

> Date: 2026-05-13
> Source: turn 1 user request

## Verdict

Summary: 3 PASS · 1 PARTIAL · 1 FAIL (out of 5)

## Audit table

| # | Requirement | Status | Evidence |
|---|---|---|---|
| 1 | Migrate password hashing from bcrypt to argon2 | ✅ PASS | `internal/auth/hash.go:14–62`; `go test ./internal/auth/...` passes |
| 2 | Keep bcrypt verification path for existing users | ✅ PASS | `internal/auth/hash.go:64–81`; covered by `TestHashCompatibility` |
| 3 | Add a one-time migration that re-hashes on next login | ⚠ PARTIAL | `internal/auth/login.go:120–140` rehashes; migration script not yet generated |
| 4 | Update the auth runbook with the rollout plan | ❌ FAIL | `docs/runbook/auth.md` not modified; rollout plan absent |
| 5 | Bump the auth schema version | ✅ PASS | `migrations/0042_auth_v2.sql`; `make migrate-status` shows applied |

## Follow-ups

- Generate the migration script for #3.
- Update `docs/runbook/auth.md` with the rollout plan for #4.
```

## Status iconography rationale

- **✅ PASS** — visually positive, scans easily.
- **⚠ PARTIAL** — caution glyph signals "look closer."
- **❌ FAIL** — unambiguous; nobody confuses ❌ with PASS.
- **➖ N/A** — neutral dash; visually distinct from the others.

Do not invent additional statuses. Five is the entire vocabulary. If a row
does not fit, the requirement was probably ambiguous; run cognitive-alignment
and re-anchor.
