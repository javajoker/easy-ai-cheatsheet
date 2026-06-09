# Version Matrix

Cross-version reference for `skill-version-tune`. Three sections:

1. **Capability comparison at a glance** — which worker owns what.
2. **The `tuned-for` metadata spec** — the one new field this family adds.
3. **Capability → skill-shape change** — the mapping that drives the
   Phase 2 gap analysis.

> Every per-version claim below carries a provenance tag. `(confirmed)` =
> verifiable from the runtime environment / this harness. `(inferred)` =
> plausible per-version delta that **must** be checked against the model or
> Claude Code release notes before a proposal relies on it. The
> authoritative sources are `docs.claude.com` (model + API) and the Claude
> Code release notes / changelog.

## 1. Capability comparison at a glance

This is a *map*, not a changelog. The detail lives in each worker's
`references/capabilities.md`. The point here is to show what is shared
across the Opus 4.x family versus what is a per-version delta.

| Capability area | 4.6 | 4.7 | 4.8 | Notes |
|---|---|---|---|---|
| Opus 4.x model family member | ✓ | ✓ | ✓ | `(confirmed)` — Opus 4.x is the current family; IDs `claude-opus-4-8`, etc. |
| Fast mode (`/fast`, Opus at faster output, not a downgrade) | ✓ | ✓ | ✓ | `(confirmed)` — available on Opus 4.6 / 4.7 / 4.8 |
| Extended / interleaved thinking | ✓ | ✓ | ✓ | `(confirmed)` family capability; per-version quality + effort-control surface is `(inferred)` |
| Effort control | — | — | ✓? | `(inferred)` — confirm which versions expose an effort/verbosity control and how |
| Larger effective context / better long-context use | →| → | → | `(inferred)` — direction of travel across the family; exact windows from release notes |
| Tool-use reliability (parallel calls, long tool chains) | →| → | → | `(inferred)` per-version; parallel tool calls themselves are a *harness* capability (see `tune-for-cc-harness`) |
| Knowledge cutoff | — | — | Jan 2026 | `(confirmed)` for the running model; older versions' cutoffs from release notes `(inferred)` |

`→` means "improves along the family but the per-version number is not
something this sheet asserts — read the release notes." The honest position
is: **4.6, 4.7, and 4.8 share a large common baseline; the precise deltas
between them are `(inferred)` here and must be confirmed.** Where a tune
depends on a specific delta, the proposal says so.

The CC harness is a **separate axis** — see
`tune-for-cc-harness/references/capabilities.md`. A skill can be behind on
the model, the harness, or both.

## 2. The `tuned-for` metadata spec

`tuned-for` is the single new front-matter field this family introduces. It
is **additive and optional** — every existing skill in the framework
carries only `name` + `description`, and the absence of `tuned-for` means
"never explicitly version-tuned," which is a valid state.

### Shape

```yaml
---
name: task-breakdown
description: ...
tuned-for: [opus-4-8, cc-harness-2026-06]
---
```

- A **list** of version tokens. A skill can be current on several axes.
- Model tokens: `opus-4-6`, `opus-4-7`, `opus-4-8`.
- Harness token: `cc-harness-<YYYY-MM>` — dated, because the harness has no
  public semver and ships continuously. The date is the month the tune was
  performed against the then-current harness.

### Who writes it

`skill-version-tune` does **not** write `tuned-for` — it only emits
proposals. `skill-merge` writes it when it applies the proposals, in the
same Phase 4 step where it bumps `version:`/`updated:`. The proposals carry
`tuned-for:` in *their* front matter (provenance for the proposal); the
merge promotes the token onto the *target skill's* front matter.

### How it interacts with `skill-merge`'s version bump

`tuned-for` is orthogonal to the semver `version:` field. A version-tune
proposal still bumps `version:` by its `kind` (patch for description /
anti-pattern / reference; minor for procedure / wiring). `tuned-for` is the
*reason* axis, `version:` is the *magnitude* axis. Both move; neither
replaces the other.

### Idempotence

Before Phase 2, `skill-version-tune` reads the target's `tuned-for`. If the
target version token is already present, only propose **deltas** — changes
not covered by the prior tune. This stops a second 4.8 run from re-emitting
the first run's proposals. A re-tune is legitimate when the *harness date*
has moved (`cc-harness-2026-06` → `cc-harness-2026-11`) or when the worker's
capability sheet itself has been updated since the last tune.

## 3. Capability → skill-shape change

The gap analysis (dispatcher Phase 2) is a search for these patterns. Each
row is "if the skill does X and the version offers Y, propose Z." Use it as
the checklist; not every row applies to every skill.

| If the skill currently… | …and the version offers… | …propose (kind) |
|---|---|---|
| Asks the user questions one at a time across turns | Strong instruction-following + batched reasoning | Consolidate into one upfront question block (`procedure`) — mirrors what `skill-orchestrator` already does |
| Runs independent reads/edits sequentially | Native **parallel tool calls** (harness) | Batch independent calls into one step (`procedure`) |
| Tells the model to "keep it short so context doesn't overflow" | Larger effective context + **context compaction** (harness) | Relax the budget caveat; lean on compaction; point at `compact-ritual` (`procedure` + `wiring`) |
| Hand-rolls a fan-out search or a sub-task loop | **Subagents** via the Agent tool (harness) | Delegate the fan-out to an `Explore`/`general-purpose` subagent (`procedure` + `wiring`) |
| Does a big irreversible action with no checkpoint | **Plan mode** (harness) | Add a plan-mode checkpoint before the irreversible step (`procedure`) |
| Re-derives durable facts every session | **Memory** store + `memory-ontology` (harness) | Persist the fact; cross-link `memory-ontology` (`wiring`) |
| Has a heavy single reasoning step done at default depth | **Extended thinking / effort control** (model) | Call for deeper thinking / higher effort *only* on that step (`procedure`) |
| Never mentions a relevant native mechanic (Skills, MCP, worktrees) | That mechanic exists in the harness | Cross-link it (`wiring`) or document the technique (`reference`) |
| Assumes a knowledge cutoff older than the running model's | Newer cutoff (`(confirmed)` for the running model) | Update stale "the model won't know about X after DATE" caveats (`description`/`reference`) |

**The discipline that makes this safe:** a row is only a finding when the
"if" clause genuinely matches the skill *and* the payoff is concrete. A
skill that already batches its questions has no finding on row 1. The
mapping is a sieve, not a stamp.
