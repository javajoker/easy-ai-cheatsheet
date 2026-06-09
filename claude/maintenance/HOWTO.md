# HOWTO — running a version tune

Everyday mechanics for the maintenance layer. For the layer rationale and the
family map, see [README.md](README.md); for the full step-by-step playbook
(when it fits, the new-role branch, the manual fallback, and what it does
*not* cover), see [SCENARIO-U.md](SCENARIO-U.md). This file is self-contained
— you do not need to read the top-level `HOWTO.md` to use the family.

When a new Claude model lands (Opus 4.6 → 4.7 → 4.8) or the Claude Code
harness gains capabilities (subagents, plan mode, background tasks, context
compaction, the Skill/MCP systems, worktrees), your existing skills, agents,
and INSTRUCTIONS do **not** automatically exploit it. They were authored
against whatever the model and harness could do the day they were written.
The version-tuning family closes that gap on demand — and like the evolution
loop, it never rewrites a file silently.

## The shape of the family

One dispatcher per layer, four shared per-version capability workers:

| You want to tune a… | Run this dispatcher | Lives at |
|---|---|---|
| **skill** (`SKILL.md`) | `skill-version-tune` | `skill-version-tune/` |
| **agent** (`AGENT.md`) | `agent-version-tune` | `agent-version-tune/` |
| **INSTRUCTIONS** file (always-loaded) | `instructions-version-tune` | `instructions-version-tune/` |

All three load the same provenance-tagged capability sheets under
[`versions/`](versions/) — `tune-for-opus-4-6`, `tune-for-opus-4-7`,
`tune-for-opus-4-8`, and `tune-for-cc-harness` — and apply their own layer
lens on top. When a version makes a *whole new role* viable,
`agent-version-tune` hands off to [`agent-create/`](agent-create/), which
scaffolds and registers a brand-new agent.

## Running a tune

```
> Tune the task-breakdown skill for the current Claude Code harness.
> Modernise the devops-engineer agent for Opus 4.8.
> Update claude-code-best-practices.md for subagents and plan mode.
```

The dispatcher will:

1. **Confirm the target version is actually reachable** — it detects the
   running model from the environment if you said "the latest," and never
   tunes toward a version your runtime doesn't have.
2. **Load the capability sheet** and walk the target against it. Each
   capability is tagged `(confirmed)` (verifiable from the runtime) or
   `(inferred)` (a per-version delta to confirm against release notes).
3. **Emit one atomic `skill-evolution` proposal per real finding**, tagged
   `tuned-for: opus-4-8` (or `cc-harness-<YYYY-MM>`). Then you run
   `skill-merge` exactly as in the evolution loop — diff preview, your
   approval, version bump.
4. On merge, stamp an additive `tuned-for:` field on what it tuned, so the
   *next* tune only proposes deltas (idempotent — it won't re-suggest what
   already landed).

`skill-evolution` and `skill-merge` are the shared proposal/merge machinery —
they live under [`../skills/share/`](../skills/share/) and are reused
unchanged. Only the *source* of a proposal differs here (a capability-sheet
line instead of a live observation).

## Two disciplines that keep it honest

- **Tune the layer that's actually behind.** An agent is mostly a
  composition of skills; an "agent gap" is often really a gap in a skill it
  composes. Tune the skill, not the agent, when that's the real target.
- **Capability findings are a *subset* of capabilities.** A capability your
  skill genuinely doesn't need is not a gap. Cargo-culting "use a subagent
  here" into a two-second step makes things worse. The dispatchers reject
  non-findings by design.

## How this differs from "evolving a skill through use"

| | Evolution loop | Version tune |
|---|---|---|
| **Trigger** | A failure/gap observed in live work | A new model/harness capability |
| **Evidence** | What happened in the session | The capability sheet line (+ provenance) |
| **Entry** | `skill-evolution` | `skill-version-tune` / `agent-version-tune` / `instructions-version-tune` |
| **Apply** | `skill-merge` (shared) | `skill-merge` (shared) |

Both produce proposals; both land through the same human-checkpointed merge.
The version-tune family just *sources* its proposals from a capability sheet
instead of a live observation. The failure-driven sibling is
[`../skills/share/skill-evolution/`](../skills/share/skill-evolution/) (its
own playbook is Scenario L in the top-level `SCENARIOS.md`).
