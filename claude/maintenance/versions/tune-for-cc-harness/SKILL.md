---
name: tune-for-cc-harness
description: The current-Claude-Code-harness capability lens for skill-version-tune. Loads when a skill is being retuned to make full benefit of Claude Code harness features — parallel tool calls, subagents (the Agent tool), background tasks, plan mode, context compaction, the Skill and MCP systems, the memory store, worktrees, hooks, permission modes, and fast mode. Use this worker when the user says "tune this skill for the current Claude Code", "use the harness features", "this skill predates subagents/plan mode/compaction — modernise it", or when skill-version-tune routes a harness-axis retune here. Provides the harness capability checklist and the full capability sheet (references/capabilities.md); the actual gap analysis and proposal emission stay in the skill-version-tune dispatcher.
---

# Tune for the current Claude Code harness

A **worker skill** for `skill-version-tune`. It does not run the retune on
its own — the dispatcher owns Phases 0–5. This skill provides the **harness
capability lens**: what the current Claude Code harness can do, and the
checklist for spotting where an existing skill leaves that on the table.

> The harness has no public semver and ships continuously. Tag a harness
> tune with a **dated** token — `cc-harness-<YYYY-MM>` — not a version
> number. Re-tuning later, when the harness has moved, is legitimate; the
> date is how `tuned-for` distinguishes the two passes.

## What's distinctive about the harness axis

The model and the harness are different things. The *model* (Opus 4.x)
reasons; the *harness* (Claude Code) gives it tools, parallelism, memory,
subagents, checkpoints, and lifecycle. A skill can be perfectly tuned for
the model and still ignore everything the harness added since it was
written. This worker is about the harness half.

Almost every capability here is `(confirmed)` — it is observable in the
running harness, not inferred from a changelog. That makes harness tunes
unusually safe: the proposals rest on facts, not hypotheses.

## The harness capability checklist

Apply these in the dispatcher's Phase 2 gap analysis. Each maps to a row in
the capability → skill-shape table in
`skill-version-tune/references/version-matrix.md`.

1. **Parallel tool calls.** Does the skill issue independent reads/edits one
   at a time? Batch them into a single step.
2. **Subagents (Agent tool).** Does the skill hand-roll a fan-out search or
   a multi-step sub-job inline? Delegate to an `Explore` / `general-purpose`
   subagent — but only above a size threshold (subagents start cold).
3. **Background tasks.** Does the skill block on a long-running command
   (build, test suite, deploy watch)? Run it in the background and react on
   completion.
4. **Plan mode.** Does the skill take a large or irreversible action with no
   checkpoint? Add a plan-mode gate before it.
5. **Context compaction + larger window.** Does the skill defensively
   truncate output "so context doesn't overflow"? Relax the caveat and lean
   on compaction; cross-link `compact-ritual`.
6. **Memory store.** Does the skill re-derive durable facts every session?
   Persist them; cross-link `memory-ontology`.
7. **Skill system.** Does the skill describe a procedure another skill
   already owns? Cross-link instead of duplicating.
8. **MCP tools.** Does the skill assume only built-in tools when an MCP
   server would do the job natively (browser, docs, a connector)?
9. **Worktrees.** Does the skill do risky multi-file work on the main
   branch? Note that isolated worktrees exist for it.
10. **Hooks + permission modes.** Does the skill ask the user to "remember
    to do X every time"? That is a hook, configured in settings — not a
    thing the model can promise.

Reject any item the skill genuinely doesn't need. A linting skill probably
has no subagent finding; a research skill probably does.

## Companion skills

| When… | Use |
|---|---|
| Running the actual retune (Phases 0–5) | `skill-version-tune` (the dispatcher — this worker feeds it) |
| Same harness lens, but the target is an agent / INSTRUCTIONS file | `agent-version-tune` / `instructions-version-tune` |
| Writing the proposals | `skill-evolution` |
| Applying them | `skill-merge` |
| A compaction-related relaxation needs the survival procedure | `compact-ritual` |
| A memory-persistence finding needs the durable store | `memory-ontology` |

## Anti-patterns

- **Adding harness features a skill doesn't use.** A subagent finding on a
  two-second step is cargo-culting. The checklist is a sieve.
- **Versioning the harness with a number.** Use the dated token.
- **Promising hook behaviour in prose.** "From now on the skill will always
  do X" is a `settings.json` hook, not a skill instruction — route those to
  the `update-config` mechanism, don't bake a false promise into the skill.

## Reference files

- `references/capabilities.md` — the full harness capability sheet:
  per-capability rows, provenance tags, what each enables, and the
  skill-shape change it implies.
