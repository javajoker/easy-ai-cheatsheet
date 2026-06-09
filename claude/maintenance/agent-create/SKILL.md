---
name: agent-create
description: Scaffold a new agent (a role-shaped orchestrator under claude/agents/<name>/) following the framework's "Adding a new agent" procedure and the AGENT.md frontmatter contract. Produces the AGENT.md (frontmatter + role + when-to-fire + phase workflow + skills_used + deliverable contract + companion agents + anti-patterns), registers the agent in agents/CHECKLIST.md and the agents/README.md table at the right status (draft/stub/shipped), and lists the SCENARIOS + orchestrator-wiring follow-ups. Use this skill when the user says "create a new agent for X", "we keep chaining the same skills — make it an agent", "scaffold an agent that owns the <job> arc", when agent-group-formation recommends a new agent for an unstaffed role, or when agent-version-tune finds a model/harness capability that warrants a brand-new role. Human-checkpointed: surfaces the drafted AGENT.md before writing, and never invents a deliverable contract the user hasn't confirmed. Pairs with agent-group-formation (upstream — names the gap), agent-version-tune (upstream — a version makes a role newly viable), scenario-strategist (formalises the workflow + skill list), and skill-orchestrator (the new agent must be wired into its catalogue read).
---

# Agent Create

The skill that turns *"this recurring chain of skills is really a job"*
into a registered agent. The `agents/README.md` "Adding a new agent"
section is a six-step manual procedure; this skill mechanizes it with the
framework's checks intact.

> **An agent is a job, not a task.** Before scaffolding, confirm the
> candidate clears the bar in `agents/README.md`'s anti-patterns: it spans
> *multiple* skills across *phases*, owns a *deliverable contract*, and is
> not a wrapper around one skill. If it fails that bar, it is a skill (use
> the skill creator), not an agent. Do not scaffold an agent to satisfy a
> request that a single skill already covers.

## When to fire

- The user says "create / scaffold / add an agent for <job>."
- `agent-group-formation` produced a **missing-role** row with a
  "create new agent" recommendation (it reads `agents/CHECKLIST.md` and
  finds no shipped agent for a required phase).
- `agent-version-tune` finds that a model/harness capability makes a
  *new* role viable that wasn't before, and recommends creating it.
- The orchestrator notices the same skill chain recurring for the same
  request shape and promotes it to a named agent.

Do **not** fire when:

- The "agent" is one skill in a trench coat (anti-pattern).
- The job already has a shipped agent — that's a tune (`agent-version-tune`)
  or an evolution (`skill-evolution`), not a new agent.
- The role has no deliverable contract anyone can name — formalise it with
  `scenario-strategist` first, then come back.

## Procedure

### Phase 1 — Qualify the role

Confirm the five questions `agents/README.md` requires every agent to
answer: **role**, **when to fire**, **skills used (in order)**,
**workflow (phases)**, **deliverables + verification**. If any is
unanswerable, the role isn't ready — route to `scenario-strategist`
(`workflow-design` + `agent-group-formation`) to formalise it, then resume.

Cap intake at a few questions; the rest is derived. The non-negotiable
inputs are the **deliverable contract** (what artifacts prove the job is
done) and the **single-owner** rule (each deliverable has exactly one agent
on the hook — no co-ownership).

### Phase 2 — Resolve the skill set against the live catalogue

Read `agents/CHECKLIST.md` to know what's shipped vs stub vs missing — do
**not** hardcode the skill list. Split `skills_used` into:

- `shipped:` — skills that exist now (reference them by role, not by a name
  that may change).
- `proposed:` — named gaps with no skill folder yet (these become
  `skill-creator` / `skill-evolution` follow-ups).

If a required skill is missing, record it as `proposed` and surface it as a
follow-up — do not block the agent scaffold on it.

### Phase 3 — Draft the AGENT.md

Fill `references/agent-template.md` (the AGENT.md skeleton). Frontmatter
follows the `agents/README.md` contract exactly:

```yaml
---
name: <kebab-case-name>
role: <one-line persona>
focus_area: <lifecycle | architecture | scenario | devops | knowledge | feature | …>
status: draft        # new agents start draft (or stub if frontmatter-only)
fires_on: [ … ]
skills_used:
  shipped: [ … ]
  proposed: [ … ]
deliverables: [ … ]   # one per major output
companion_agents: [ … ]
---
```

Body sections mirror the shipped agents (e.g. `feature-development`):
Why this agent exists · When to fire (with explicit "do not fire") ·
The N-phase workflow (each phase: Trigger / Skills / Output) ·
Inputs gathered upfront (capped) · Companion agents · Companion skills ·
Anti-patterns · **Deliverable contract** (the numbered done-list) ·
Reference files.

`focus_area` may extend the existing enum — if the new agent doesn't fit
`lifecycle | architecture | scenario | devops | knowledge | feature`, add a
new value and note it in the README table.

### Phase 4 — Checkpoint the draft

Surface the full drafted AGENT.md to the user before writing anything.
This is the safety moment — an agent with a wrong deliverable contract
mis-shapes every run that fires it. On approval, write
`agents/<name>/AGENT.md`.

### Phase 5 — Register (the wiring the manual procedure forgets)

A scaffolded-but-unregistered agent is invisible. Apply the six-step
`agents/README.md` registration, tracked in
`references/new-agent-checklist.md`:

1. `agents/<name>/AGENT.md` written (Phase 4).
2. **`agents/CHECKLIST.md`** — add a per-agent status block at the correct
   status (`draft` / `stub` / `shipped`) using the file's vocabulary, listing
   shipped vs proposed dependent skills.
3. **`agents/README.md`** — add a row to "The shipped agents" table (or a
   "draft agents" note if not yet shipped) and, if `focus_area` is new,
   to the focus-area enum.
4. **`SCENARIOS.md`** — add (or flag as follow-up) a scenario documenting
   when the agent fires. A new agent without a scenario is `draft`, not
   `shipped`.
5. **`skill-orchestrator` catalogue** — ensure the orchestrator can prefer
   the named agent over re-planning the chain (it reads `agents/CHECKLIST.md`
   at runtime, so step 2 usually suffices; verify).
6. **`companion_agents` mirror** — every agent named in the new agent's
   `companion_agents` should name it back if the partnership is bidirectional.

Surface which steps landed and which are deferred follow-ups (e.g. a
SCENARIOS entry the user wants to write later) — don't silently skip them.

### Phase 6 — Memory hook

Write a `type: project` memory via `memory-ontology` recording the new
agent's identity, its deliverable contract, and its current status, so a
later session can promote it `draft → shipped` when the scenario + skills
land.

## Status discipline

New agents start at **`draft`** (AGENT.md complete, but scenario/skills may
be pending) or **`stub`** (frontmatter + intent only). Promote to
**`shipped`** only when: all dependent skills exist, a SCENARIOS entry
exists, and the deliverable contract is real. The CHECKLIST vocabulary
(`shipped / draft / stub / missing`) is the source of truth — match it.

## Companion skills

| When… | Use |
|---|---|
| The role isn't yet formalised (no clear workflow/skill list) | `scenario-strategist` → `workflow-design` + `agent-group-formation` |
| `agent-group-formation` named the missing role | `agent-group-formation` (upstream — it produces the "create new agent" recommendation this skill acts on) |
| A model/harness version made a new role viable | `agent-version-tune` (upstream) |
| A dependent skill is `proposed` (doesn't exist yet) | `skill-creator` (new skill) / `skill-evolution` (extend an existing one) |
| Defining what passes between the new agent and its neighbours | `agent-handoff-protocol` |
| Persisting the new agent's identity + status across sessions | `memory-ontology` (`type: project`) |

## Anti-patterns

- **Agent = one skill in a trench coat.** If the whole workflow is "call
  skill X," it's a skill. The `agents/README.md` anti-pattern list is the
  gate.
- **Scaffold without registering.** An unregistered agent (no CHECKLIST
  row, no README entry) can't fire. Phase 5 is the point.
- **Inventing a deliverable contract.** Don't fabricate artifacts the user
  hasn't confirmed. A vague "help with X" is a category, not an agent.
- **Hardcoding skill names.** Reference skills by role; let the orchestrator
  resolve to the current name. Skills get renamed; agents shouldn't break.
- **Two agents owning one artifact.** Each deliverable, exactly one owner.
- **Shipping a draft.** `status: shipped` requires the scenario + skills +
  contract to actually exist. Until then it's `draft`.

## Reference files

- `references/agent-template.md` — the fill-in AGENT.md skeleton
  (frontmatter contract + body sections), matching the shipped agents.
- `references/new-agent-checklist.md` — the Phase-5 registration checklist
  (the six steps from `agents/README.md`, plus the status-promotion gate).
