# Capability Sheet — current Claude Code harness

The harness capabilities `skill-version-tune` checks a skill against. Each
row: the capability, a **provenance tag**, what it enables, and the
**skill-shape change** it implies when a skill isn't using it.

Provenance:
- `(confirmed)` — observable in the running harness (this session uses it).
- `(inferred)` — plausible but version/config-dependent; verify against the
  Claude Code release notes / docs before a proposal relies on it.

> Harness token for `tuned-for`: `cc-harness-<YYYY-MM>` (dated — the harness
> ships continuously). When you perform a tune, stamp the current month.

---

## Core execution

### Parallel tool calls `(confirmed)`
Independent tool calls issued in one assistant turn execute concurrently.
- **Enables:** batching independent reads/edits/searches; large latency wins
  with no quality change.
- **Skill-shape change:** rewrite "do A, then do B, then do C" into one
  batched step when A/B/C are independent. Keep serialisation only where a
  real dependency forces it.

### Subagents — the Agent tool `(confirmed)`
Spawn `Explore` / `general-purpose` / specialised agents for fan-out search
or multi-step sub-jobs; each runs with its own context.
- **Enables:** delegating broad sweeps without polluting the main context;
  parallel investigation.
- **Skill-shape change:** replace hand-rolled "search every file for X"
  loops with a delegated `Explore` agent — **above a size threshold only**,
  since agents start cold and re-derive context. Name the threshold in the
  proposal.

### Background tasks `(confirmed)`
Long-running commands (builds, test suites, deploy watches) run detached and
re-invoke the model on completion.
- **Enables:** not blocking on slow work; reacting when it finishes.
- **Skill-shape change:** any "run the test suite and wait" step becomes
  "run in background, continue, react on completion."

### Plan mode `(confirmed)`
A read-only planning phase gated by explicit user approval before
execution.
- **Enables:** a checkpoint before large or irreversible changes.
- **Skill-shape change:** skills that take a big multi-file or destructive
  action gain a plan-mode gate before the irreversible step.

## Context + memory

### Context compaction `(confirmed)`
When context grows long it is summarised and work continues across the
boundary.
- **Enables:** long sessions and fuller outputs without manual pruning.
- **Skill-shape change:** relax defensive "keep it short or context
  overflows" caveats; cross-link `compact-ritual` for the survival
  procedure. Relax — don't delete — output-discipline guidance.

### Larger effective context window `(inferred)`
The usable window has grown over the harness's life.
- **Enables:** holding more of a codebase/doc set at once.
- **Skill-shape change:** revisit budget assumptions written for a smaller
  window. Confirm the actual window from release notes before quoting a
  number in a proposal.

### Memory store `(confirmed)`
A persistent file-based memory survives across sessions (this framework
wraps it with `memory-ontology`).
- **Enables:** durable user/project facts without re-derivation.
- **Skill-shape change:** skills that re-ask or re-discover the same fact
  each session should persist it and cross-link `memory-ontology`.

## Composition systems

### Skill system `(confirmed)`
Skills are discoverable by description and invoked on demand (this very
framework).
- **Enables:** composition instead of duplication.
- **Skill-shape change:** a skill re-describing a procedure another skill
  owns should cross-link it (`wiring`) rather than restate it.

### MCP tools / servers `(confirmed)`
External capabilities (browser control, doc systems, connectors) surface as
tools, including via deferred-tool search.
- **Enables:** native integrations the skill would otherwise hand-wave.
- **Skill-shape change:** skills assuming only built-in tools can name the
  relevant MCP path when one exists (browser automation, a connector).

### Deferred tools / ToolSearch `(confirmed)`
Large tool sets are loaded on demand by name search.
- **Enables:** access to a wide tool surface without it all being preloaded.
- **Skill-shape change:** mostly transparent; relevant only for skills that
  enumerate "available tools" — those lists are now dynamic.

## Workflow + lifecycle

### Worktrees `(confirmed)`
Work can run in an isolated git worktree (this session is in one).
- **Enables:** risky multi-file changes off the main branch.
- **Skill-shape change:** skills doing large refactors can note the isolated
  worktree option.

### Hooks + permission modes `(confirmed)`
Automated, harness-executed behaviours are configured in `settings.json`;
permission modes gate tool calls.
- **Enables:** "always do X before/after Y" enforced by the harness.
- **Skill-shape change:** a skill that asks the model to "remember to do X
  every time" is describing a hook. Route that to the config mechanism
  (`update-config`); do not bake an unenforceable promise into the skill.

### Fast mode `(confirmed)`
`/fast` runs Claude Opus with faster output (not a smaller model); available
on Opus 4.8 / 4.7 / 4.6.
- **Enables:** lower latency without a capability downgrade.
- **Skill-shape change:** rarely a skill-level finding — it is a user toggle,
  not a skill behaviour. Note it only where a skill explicitly reasons about
  latency/cost trade-offs.

---

## How to use this sheet

1. The dispatcher walks a target skill against the **checklist** in this
   worker's SKILL.md (which mirrors these rows).
2. Each genuine gap becomes one atomic `skill-evolution` proposal,
   `tuned-for: cc-harness-<YYYY-MM>`.
3. `(confirmed)` rows ship proposals with confidence. `(inferred)` rows
   (larger window) require a release-note check named in the proposal's
   Risks section.

**Verify against release notes:** the Claude Code changelog / release notes
and `docs.claude.com`. This sheet is anchored on what the running harness
demonstrably does; treat anything tagged `(inferred)` as needing
confirmation, and refresh the whole sheet when the harness moves.
