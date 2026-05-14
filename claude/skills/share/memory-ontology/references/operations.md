# Memory ontology — worked operations

Walks each of the five operations end-to-end with realistic content.

## Save

User says: *"I'm a senior platform engineer, my primary stack is Go and
PostgreSQL."*

Scan: no existing `user_role.md`. Safe to create.

File `memory/user_role.md`:

```markdown
---
name: Role and stack
description: senior platform engineer, Go + PostgreSQL primary
type: user
scope: global
created: 2026-05-13
status: active
---

Senior platform engineer. Primary stack: Go, PostgreSQL. Comfortable in
TypeScript when needed. Prefers code examples in Go unless a task is
explicitly frontend.
```

Append to `MEMORY.md` under `## Global — user`:

```
- [Role and stack](user_role.md) — senior platform engineer, Go + PostgreSQL primary
```

## Update — refinement, not contradiction

Three weeks later the user mentions: *"I'm also doing the Rust evaluation for
the new pipeline."*

This refines, not contradicts. Open `user_role.md`:

```markdown
---
name: Role and stack
description: senior platform engineer, Go + PostgreSQL primary; evaluating Rust for new pipeline
type: user
scope: global
created: 2026-05-13
updated: 2026-06-03
status: active
---

Senior platform engineer. Primary stack: Go, PostgreSQL. Comfortable in
TypeScript when needed. Currently evaluating Rust for a new data-pipeline
project. Prefers code examples in Go unless a task is explicitly frontend or
the Rust pipeline.
```

Update the index line in `MEMORY.md`:

```
- [Role and stack](user_role.md) — senior platform engineer, Go + PostgreSQL primary; evaluating Rust
```

## Supersede

User previously said *"I prefer big batched PRs."* Today: *"Actually I want
small focused PRs from now on — the big ones are too hard to review."*

The old memory is `feedback_pr_size.md`:

```markdown
---
name: PR sizing
description: prefers larger batched PRs to amortize review overhead
type: feedback
scope: global
created: 2026-02-15
status: active
---

User prefers larger PRs that batch several related changes. Rationale: reduces
review overhead.

How to apply: when splitting work, prefer one well-described PR over three
smaller ones.
```

Step 1 — mark the old one superseded:

```markdown
---
name: PR sizing
description: (superseded 2026-06-03 — prefers larger batched PRs to amortize review overhead)
type: feedback
scope: global
created: 2026-02-15
status: superseded
superseded-by: feedback_pr_size_small.md
---

(body unchanged — kept for the record)
```

Step 2 — create the new one `feedback_pr_size_small.md`:

```markdown
---
name: PR sizing (revised)
description: prefers small focused PRs since big ones become hard to review
type: feedback
scope: global
created: 2026-06-03
status: active
supersedes: feedback_pr_size.md
---

User prefers small, focused PRs. Reason: the large batched style they used
earlier in 2026 produced PRs that were "too hard to review" — explicit user
quote from session on 2026-06-03.

How to apply: when splitting work, default to one logical change per PR. If a
single PR is exceeding ~400 lines or spanning more than two concerns, propose
splitting before writing.
```

Step 3 — update `MEMORY.md`:

```
## Global — feedback
- [PR sizing (revised)](feedback_pr_size_small.md) — small focused PRs preferred ≺ supersedes: feedback_pr_size.md

## Archive — feedback
- [PR sizing](feedback_pr_size.md) — superseded 2026-06-03
```

## Forget

User says: *"Forget my role memory — I just changed jobs and that's not me
anymore."*

Step 1 — delete `user_role.md`.

Step 2 — remove the `MEMORY.md` line.

Step 3 — grep every remaining memory file for `user_role.md` references. If
any `related:` or `supersedes:` lists include it, edit those files to remove
the entry.

Step 4 — confirm the cleanup with the user: *"removed user_role.md and three
stale `related:` references in other memories."*

## Audit

Triggered during the compact-ritual or onboarding. Walk every file under
`memory/`. For each:

1. Does the description in the file match the line in `MEMORY.md`?
   - Mismatch: trust the file, repair the index.
2. Are all `supersedes` / `superseded-by` filenames resolvable?
   - Dangling: report. Do not auto-repair — the user may have intended a name
     change.
3. Are all `related:` entries resolvable and reciprocal?
   - Missing back-edge: report. Repair only on confirmation.
4. For `project:<slug>` scope, does the slug still exist?
   - Archived project: ask the user whether to mark `status: superseded` or
     change scope.
5. For `type: project` with `created:` more than 90 days old and no `updated:`,
   verify with the user that the fact still holds.

Output of audit is a short report:

```
Audit pass — 2026-06-03

- user_role.md: index description out of date — repaired.
- feedback_mocks.md: related entry feedback_tests_old.md missing — needs decision.
- project_coolshell_freeze.md: created 2026-03-05, deadline was 2026-03-05 — stale, propose archive.
```

The user decides; the audit only flags.
