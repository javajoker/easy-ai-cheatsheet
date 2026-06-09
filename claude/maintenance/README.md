# maintenance — keeping the framework current with model & harness versions

The **maintenance layer** holds the framework's *self-tuning* resources: the
skills that retune the framework's own artifacts — other skills, agents, and
always-loaded INSTRUCTIONS — when a new Claude model lands (Opus 4.6 → 4.7 →
4.8) or the Claude Code harness gains capabilities (subagents, plan mode,
background tasks, context compaction, the Skill/MCP systems, worktrees).

This is **capability-driven** maintenance, distinct from the failure-driven
[evolution loop](../skills/share/skill-evolution/) (`skill-evolution` +
`skill-merge`, which stay under `skills/share/` and are reused here). The full
playbook lives right here as **[SCENARIO-U.md](SCENARIO-U.md)** and the
everyday mechanics as **[HOWTO.md](HOWTO.md)** — no need to leave this folder.
Everything here is human-checkpointed — it never rewrites a file silently.

This folder is **self-contained**: `README.md` (this file, the overview),
`HOWTO.md` (how to run a tune), and `SCENARIO-U.md` (the full playbook)
together cover everything you need to use the family. The top-level
`HOWTO.md` and `SCENARIOS.md` only keep short pointers back here.

## Why this is a top-level layer

`INSTRUCTIONS/`, `agents/`, and `skills/` are the framework's *content*: what
you use to do project work. `maintenance/` is the *meta* layer: what you use
to keep that content current as the model and harness move underneath it.
Pulling it out of `skills/share/` keeps the project axis (what you build) and
the model/harness-version axis (what you tune for) visibly separate.

## Layout

```
maintenance/
├── README.md                       # this file
├── skill-version-tune/             # dispatcher — retunes a skill (SKILL.md)
├── agent-version-tune/             # dispatcher — retunes an agent (AGENT.md); branches to agent-create
├── instructions-version-tune/      # dispatcher — retunes an always-loaded INSTRUCTIONS file
├── agent-create/                   # scaffolds + registers a brand-new agent when a version makes a role viable
└── versions/                       # per-model / per-harness capability sheets (provenance-tagged)
    ├── tune-for-opus-4-6/          # Opus 4.6 capability lens
    ├── tune-for-opus-4-7/          # Opus 4.7 capability lens
    ├── tune-for-opus-4-8/          # Opus 4.8 capability lens
    └── tune-for-cc-harness/        # current Claude Code harness capability lens
```

## The shape of the family

One **dispatcher per layer**, four shared **per-version capability workers**:

| You want to tune a… | Run this dispatcher |
|---|---|
| **skill** (`SKILL.md`) | `skill-version-tune` |
| **agent** (`AGENT.md`) | `agent-version-tune` |
| **INSTRUCTIONS** file (always-loaded) | `instructions-version-tune` |

All three load the same provenance-tagged sheets under `versions/` —
`tune-for-opus-4-6`, `tune-for-opus-4-7`, `tune-for-opus-4-8`, and
`tune-for-cc-harness` — and apply their own layer lens on top. Each
capability is tagged `(confirmed)` (verifiable from the runtime) or
`(inferred)` (a per-version delta to confirm against release notes); no
fabricated changelogs. When a version makes a *whole new role* viable,
`agent-version-tune` hands off to `agent-create`, which scaffolds and
registers a brand-new agent (also the destination for
`agent-group-formation`'s "create a new agent" recommendation).

## How a tune lands

Each dispatcher emits **one atomic `skill-evolution` proposal per real
finding**, stamped with an additive `tuned-for: <version>` field, then you
apply it through the shared **`skill-merge`** loop — diff preview, your
approval, version bump — exactly as in the evolution loop. The next tune only
proposes deltas (idempotent). The shared proposal/merge machinery is reused
unchanged from `skills/share/`; only the *source* of a proposal differs (a
capability-sheet line instead of a live observation).

## Pointers

In this folder (canonical):

- **Full playbook:** [SCENARIO-U.md](SCENARIO-U.md)
- **Everyday mechanics:** [HOWTO.md](HOWTO.md)

Elsewhere in the framework:

- **Failure-driven sibling (Scenario L):** [`../skills/share/skill-evolution/`](../skills/share/skill-evolution/) + [`../skills/share/skill-merge/`](../skills/share/skill-merge/)
- **Where this sits in the whole framework:** [`../README.md`](../README.md)
