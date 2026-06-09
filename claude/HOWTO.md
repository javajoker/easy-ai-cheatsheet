# HOWTO — using this framework with Claude Code

A practical guide. If you have a specific situation, jump to
[SCENARIOS.md](SCENARIOS.md). This file covers the everyday mechanics.

## Installation

There are two ways to use this framework:

### Option 1 — as your global Claude Code config

Symlink or copy the directories into `~/.claude/`:

```bash
# From the repo root:
ln -s "$(pwd)/claude/INSTRUCTIONS" ~/.claude/INSTRUCTIONS
ln -s "$(pwd)/claude/skills"       ~/.claude/skills
ln -s "$(pwd)/claude/agents"       ~/.claude/agents
```

This makes the entire framework available in every Claude Code session,
regardless of project.

### Option 2 — as a per-project `.claude/` directory

Symlink or copy under the project's `.claude/`:

```bash
# From inside a project repository:
ln -s /path/to/ai-claude/claude/INSTRUCTIONS .claude/INSTRUCTIONS
ln -s /path/to/ai-claude/claude/skills       .claude/skills
ln -s /path/to/ai-claude/claude/agents       .claude/agents
```

This scopes the framework to one project. Useful when different projects
prefer different conventions.

A hybrid pattern works too: keep the framework globally and *override*
specific instructions per-project via the project's own `.claude/CLAUDE.md`.

## What gets loaded automatically

When you start a Claude Code session, Claude reads:

1. The project's `.claude/CLAUDE.md` if it exists (the per-session
   configuration entry point).
2. Anything `CLAUDE.md` links to, including `INSTRUCTIONS/` files.
3. The list of available skills (descriptions only). SKILL.md bodies load on
   demand when a skill triggers.

That last point is important: **skills do not bloat your context until they
fire.** A long catalog is cheap.

## Triggering skills

Three triggering mechanisms:

### Implicit triggering

Most skills trigger automatically based on the user's prompt matching their
description. For example, saying *"build me a habit-tracking app"* triggers
`project-prototype` even though the skill isn't named.

The `skill-orchestrator` is the meta-skill that fires first for any
multi-step request and picks the right chain — including preferring a
**named agent** over an ad-hoc skill chain when one matches (see
[Agents — the role layer](#agents--the-role-layer) below).

### Explicit triggering

Name the skill in your prompt:

> Use the `project-backend-go` skill to generate the backend from these docs.

### Slash commands

Some skills register slash commands (where the harness supports it). The
naming convention is `/<skill-name>`.

## The four meta-skills that should always be active

Even though they live in `skills/share/`, these four should be thought of as
*always running in the background*, not as one-off tools:

1. **`cognitive-alignment`** — keeps shared meaning straight between Claude
   and you. Surfaces ambiguous terms early.
2. **`memory-ontology`** — manages `MEMORY.md` and the per-memory files
   as an ontology graph.
3. **`compact-ritual`** — protects session state through `/compact`.
4. **`skill-orchestrator`** — picks and chains other skills (and picks
   named **agents** when one fits the request).

If you go an entire session without any of these firing, something is wrong.

## Agents — the role layer

Agents sit on top of skills. They are named roles that bundle a
workflow + skills + deliverables for a specific job. The framework
ships six:

| Agent | Job |
|---|---|
| [`lifecycle-pilot`](agents/lifecycle-pilot/AGENT.md) | Prototype → production code → go-to-market launch |
| [`scenario-strategist`](agents/scenario-strategist/AGENT.md) | Scenario analysis, workflow design, agent-group formation |
| [`devops-engineer`](agents/devops-engineer/AGENT.md) | CI/CD, IaC, observability, runbooks, releases, security, secrets |
| [`architecture-shepherd`](agents/architecture-shepherd/AGENT.md) | Architecture upgrade end-to-end (assess → migrate → roll out → communicate) |
| [`knowledge-curator`](agents/knowledge-curator/AGENT.md) | Enterprise knowledge base (architecture → merge → refresh → search → ACL) |
| [`feature-development`](agents/feature-development/AGENT.md) | Add a feature to an onboarded project (spec → contract lock → code → verify → ship) |

### When the orchestrator picks an agent vs a skill chain

The orchestrator's Phase 1 now reads both the skill catalog **and**
`agents/CHECKLIST.md`. Decision flow:

| Match | Routing |
|---|---|
| Request matches one agent's `fires_on` triggers | Invoke that agent — its AGENT.md is the workflow |
| Request matches multiple agents | Engage `scenario-strategist` — it forms a group via `agent-group-formation` |
| No agent matches | Fall back to skill-level chain planning |

This means most multi-step requests are routed through agents now,
not raw skill chains.

### Invoking an agent

Three ways an agent fires:

- **Implicit (via orchestrator).** A request matching the agent's
  `fires_on` triggers routes there automatically. Saying *"take this
  idea all the way to launch"* fires `lifecycle-pilot` without
  naming it.
- **By name.** *"Use the architecture-shepherd agent to plan the
  Postgres major upgrade."*
- **By scenario.** Following a scenario from
  [SCENARIOS.md](SCENARIOS.md) M–S puts you in the right agent's
  workflow.

### What you should expect from an agent

Each agent's AGENT.md declares a **deliverable contract** — the
artifacts that prove the job is done. When the agent declares
done, every contract item exists and has been audited via
`requirement-audit`. If a contract item is missing, the agent
hasn't actually shipped.

### Agents vs skills — when to write one or the other

| If the work is… | Ship a… |
|---|---|
| One task, one job, one handoff | **Skill** |
| A coherent multi-phase *job* with deliverable contract | **Agent** |
| A recurring chain you find yourself orchestrating manually | **Agent** (promote the pattern) |
| A short ad-hoc chain | Use `skill-orchestrator` directly |

If the agent's whole workflow is *"call skill X"*, it's a skill —
not an agent. Don't add a wrapper layer.

See [agents/README.md](agents/README.md) for the agents-layer
rationale and [agents/CHECKLIST.md](agents/CHECKLIST.md) for build
status of all agents and their dependent skills.

## Working with the MEMORY ontology

The harness exposes `~/.claude/projects/<id>/memory/` as a directory of
markdown files with `MEMORY.md` as the index. This framework's
`memory-ontology` skill adds structure to that index.

When you say "remember X" or Claude proposes "should I save this?", a
memory file is written. The skill ensures:

- The right scope is chosen (global vs project).
- Existing memories are checked for contradictions.
- Relations between memories are explicit.
- The index stays under the harness's 200-line limit.

You don't have to call the skill by name. Just:

- **Tell Claude to remember a fact** → memory-ontology fires (save).
- **Tell Claude to forget X** → memory-ontology fires (forget).
- **Run `/compact`** → memory-ontology + compact-ritual fire together.
- **Open a new project for the first time** → project-onboarding fires
  and seeds memory at the end.

## Around `/compact`

The single most expensive failure mode in long sessions is losing the
cognitive library and the working state to `/compact`. The
`compact-ritual` skill handles this automatically when you signal
compaction:

### Before you run `/compact`

If you remember, say *"surface state before compacting"*. If you don't,
the skill watches for context-pressure signals and runs the pre-ritual
proactively.

The pre-ritual surfaces three tagged blocks (`<cognitive_library>`,
`<cognitive_profile>`, `<memory_ontology_snapshot>`) plus, if work is in
progress, an `<in_flight>` block.

### After `/compact` runs

Claude verifies each block survived. If something is missing or summarized
into uselessness, it asks you to confirm a reconstruction rather than
silently rebuilding.

## Language policy in practice

The rule is: **instructions are English, conversation follows the user,
artifacts follow the project**.

| What | Language |
|---|---|
| SKILL.md files | English |
| INSTRUCTIONS/*.md | English (universal portion) |
| INSTRUCTIONS/projects/<slug>/*.md | Project's primary language |
| Templates | English with `{placeholders}` |
| Cognitive library, profile, MEMORY ontology entries | User's primary language |
| Restate phrases | User's primary language |
| Code comments, error messages, commit messages | Project's primary language |
| User-facing UI copy in generated projects | Project's declared locales (English by default; project-docs asks) |

Confused which language to use? It's whichever the *reader* of that artifact
needs.

## Per-project setup

To onboard an existing project to this framework, run the
`project-onboarding` skill. The short version:

```
> Onboard this project.
```

The skill:

1. Reads the codebase (no edits).
2. Asks 3–7 targeted questions for things it cannot infer.
3. Delegates to `create-project-instruction` to write
   `INSTRUCTIONS/projects/<slug>/project-context.md` and
   `INSTRUCTIONS/projects/<slug>/repository-structure.md`.
4. Seeds memory entries.
5. Produces a short onboarding report.

If you already have the inputs and just want the INSTRUCTIONS files
written — say, after `project-docs` has produced PRD + tech design — invoke
`create-project-instruction` directly. It accepts four input modes
(existing codebase, fresh-project conversation, PRD + tech design, hybrid).

For a brand-new project from an idea, run `project-prototype` instead and
follow the chain documented in `skills/ideas/WORKFLOW.md`.

## Per-project skills

Some projects acquire an internal API surface or convention set large enough
to deserve a dedicated skill. Those skills live under `skills/projects/<slug>/`,
keyed by project slug — a namespace created on demand (none ship with the
framework, so the portable surface stays clean).

Create one when, and only when:

- The project has a substantial internal API surface (more than a couple of
  packages) that downstream code repeatedly looks up.
- Its conventions deviate enough from the portable defaults that the generic
  dev skills would produce wrong output (e.g. a custom error-wrapping helper
  instead of the stdlib one).
- It has operational quirks (release or deploy procedure) worth a dedicated
  runbook skill.

Do *not* create one when the project follows the framework defaults, or when
the "specifics" are a handful of style preferences — capture those in
`INSTRUCTIONS/projects/<slug>/conventions.md` instead.

Naming: the SKILL.md `name:` reuses the project slug with a suffix describing
the reference kind — `-rtl` (runtime library / internal API), `-conventions`
(style or layout rules), `-runbook` (operational procedures). The SKILL.md
wrapper stays English so description-based triggering works in mixed-language
environments; the `references/` content may be in the project's primary
language. Each project-specific skill typically pairs with an
`INSTRUCTIONS/projects/<slug>/` directory; `project-onboarding` produces both
sides of that pairing.

## Adding your own skill

Skills are folders under `skills/<category>/<skill-name>/` with at minimum:

- `SKILL.md` with YAML frontmatter declaring `name`, `description`, and
  optional metadata.
- Optional `references/` directory with reference docs Claude reads
  on-demand.
- Optional `scripts/` directory with helper scripts (Python, bash, etc.).
- Optional `assets/` directory with reusable templates, configs, etc.

The frontmatter `description` is the single most important field —
it is what Claude matches against user prompts to decide whether to fire
the skill. Write it like a search-friendly summary that includes:

- What the skill does.
- When to trigger (with example phrasings).
- When NOT to trigger (with the relevant alternatives).

Existing skills in `skills/ideas/` are good models.

## Updating a skill

When you edit a skill:

1. Re-read the orchestrator's references at `skills/share/skill-orchestrator/`
   to verify chain expectations still hold.
2. If you changed the description, test it against representative prompts.
3. If you changed the behaviour, surface the change to active sessions
   (don't silently change rules they were operating under).

## Evolving a skill through live use

The framework has an explicit observe → propose → merge loop for evolving
skills based on what actually happens during project work. The mechanic
is two paired skills, both kept human-checkpointed so changes are never
silent.

### Capturing an evolution candidate

During any workflow, when you (or Claude) notice that a skill could be
sharper — its description didn't match how you phrased something, its
procedure was wrong for this project size, an anti-pattern just played
out, etc. — invoke `skill-evolution`:

```
> The project-onboarding skill should also fire on "register this
> project" — please capture that as an evolution proposal.
```

The skill writes a proposal under `docs/skill-evolution/` with the
observed evidence, the current text, the proposed change, the
rationale, and the risks. **The proposal is not applied yet.** It is
just a captured idea, reviewable, persistent across sessions.

Claude will also surface candidates proactively from the orchestrator's
Phase 4 evolution-watch: at the end of a multi-skill workflow, any
proposals captured during execution are listed in the handoff.

### Reviewing and merging

When you have one or more proposals ready to land:

```
> Run skill-merge on docs/skill-evolution/2026-05-13-*.md
```

`skill-merge` runs through a checklist:

1. Gather proposals; classify by target file.
2. Detect conflicts (multiple proposals touching the same text).
3. Preview the unified diff for every target.
4. Apply only after you approve the diff.
5. Update proposal status from `proposed` to `merged`.
6. Cross-check downstream artifacts (skill-orchestrator, SCENARIOS,
   companion sections, README counts).
7. Write a feedback memory so the next session knows the catalog
   changed.

Conflicts (same-text contradictory proposals) stop the merge and ask you
to resolve — pick one, synthesize, or sequence.

### Project-specific overrides vs general evolution

Two related but distinct mechanisms:

- **Override** (lives at `INSTRUCTIONS/projects/<slug>/skill-overrides/`)
  — applies to *one* project only. Useful when this project's quirks
  contradict the canonical behaviour.
- **Evolution** (lives at `docs/skill-evolution/`) — proposes a change
  to the *canonical* skill. Once merged, every project sees it.

When in doubt, start with an override (fixes today's work without
affecting other projects). Promote to evolution when the same pattern
appears across multiple projects.

See `skills/share/skill-evolution/references/override-vs-evolution.md`
for the decision flowchart.

### What this means for the framework

The framework is now *alive* in the relevant sense: it does not modify
itself silently, but it captures the lessons of live use and offers
them back to you as reviewable changes. Over time, the skills sharpen
in the directions your actual work pushes them.

Three honest constraints to keep in mind:

1. **Claude does not write to skill files without confirmation.** The
   diff preview is non-negotiable.
2. **The user is the merge gate.** Proposals can accumulate
   indefinitely; nothing lands until you say so.
3. **Bugs are not evolution.** A skill that produces wrong output is a
   bug — fix it directly with a normal commit. Use the evolution loop
   for *refinements* with proposal evidence, not for repairs.

## Updating a skill, agent, or instructions for a new model or harness version

When a new Claude model lands (Opus 4.6 → 4.7 → 4.8) or the Claude Code
harness gains capabilities (subagents, plan mode, background tasks, context
compaction, the Skill/MCP systems, worktrees), your existing skills, agents,
and INSTRUCTIONS do **not** automatically exploit it. The **version-tuning
family** under [`maintenance/`](maintenance/README.md) closes that gap on
demand — one dispatcher per layer (`skill-version-tune` / `agent-version-tune`
/ `instructions-version-tune`), four shared per-version capability sheets
under `maintenance/versions/`, branching to `agent-create` when a version
makes a whole new role viable. Like the evolution loop, it never rewrites a
file silently: each dispatcher emits `skill-evolution` proposals that you
apply through `skill-merge`.

**The maintenance folder is self-contained — read it there, not here:**

- **How to run a tune** (the mechanics, the disciplines, evolution vs.
  version-tune): [`maintenance/HOWTO.md`](maintenance/HOWTO.md)
- **Full playbook** (when it fits, the new-role branch, manual fallback, what
  it does *not* cover): [`maintenance/SCENARIO-U.md`](maintenance/SCENARIO-U.md)
- **Layer overview + family map:** [`maintenance/README.md`](maintenance/README.md)

## When things go wrong

### "Claude isn't firing the right skill"

The description doesn't match what users actually say. Edit the description
to include user-style phrasings.

### "Claude keeps asking the same question"

A fact should be in MEMORY. Save it to `~/.claude/projects/<id>/memory/`
with the right type and scope.

### "Lost state after `/compact`"

See `skills/share/compact-ritual/references/recovery-modes.md`. Don't let
Claude silently rebuild — confirm each artifact.

### "Two skills both fire and conflict"

Skill names must be unique. Check the frontmatter `name:` fields. The
`cognitive-alignment` consolidation was triggered by exactly this kind of
collision.

## See also

- [SCENARIOS.md](SCENARIOS.md) — step-by-step playbooks. Scenarios A–L
  are skill-level; **M–T are agent-level** (one per agent + two
  multi-agent compositions); **U** is framework-maintenance (tuning to a
  model/harness update). The appendix adds two fully worked end-to-end
  examples: onboarding a project, and adding a feature.
- [agents/README.md](agents/README.md) — the role layer.
- [agents/CHECKLIST.md](agents/CHECKLIST.md) — agent + new-skill build
  status.
- `INSTRUCTIONS/README.md` — universal-instructions overview.
- `skills/ideas/README.md` and `skills/ideas/WORKFLOW.md` — project
  lifecycle skills (consumed by `lifecycle-pilot` agent).
- `skills/share/skill-orchestrator/SKILL.md` — meta-orchestration logic
  with agent-preference rules.
