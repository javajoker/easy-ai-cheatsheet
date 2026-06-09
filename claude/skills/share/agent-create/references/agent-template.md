# AGENT.md Template

Copy this when scaffolding a new agent. Save to
`claude/agents/<name>/AGENT.md`. It mirrors the shipped agents (see
`agents/feature-development/AGENT.md` for a worked example) and the
frontmatter contract in `agents/README.md`.

## Template

```markdown
---
name: <kebab-case-name>
role: <one-line persona — what this agent IS, in a sentence>
focus_area: <lifecycle | architecture | scenario | devops | knowledge | feature | NEW-value>
status: draft        # draft | stub | shipped — new agents start draft (or stub if frontmatter-only)
fires_on:
  - "<trigger phrase the user would actually say>"
  - "<repo state or scenario that should engage this agent>"
skills_used:
  shipped: [<skills that exist now — reference by role where the name may change>]
  proposed: [<named skill gaps with no folder yet — become skill-creator / skill-evolution follow-ups>]
deliverables:
  - <artifact 1 — one row per major output>
  - <artifact 2>
companion_agents: [<agents this one hands off to or receives from>]
---

# <Agent Title>

<One paragraph: the arc this agent owns, from the user's first words to
the done state.>

## Why this agent exists

<What gap in the skills/ + INSTRUCTIONS/ + existing-agents set this fills.
Name the cost of NOT having it — what goes wrong today.>

## When to fire

Fire when <conditions>:

- *"<example request>"*
- *"<example request>"*

Do **not** fire when:

- <condition that routes to a different agent / skill> — use <X> instead.
- <out-of-scope condition>.

## The <N>-phase workflow

### Phase 1 — <name>

**Trigger:** <what starts this phase>
**Skills:** <skills used, in order>
**Output:** <the artifact / state this phase produces>

<Narrative: what happens, what gate ends the phase.>

### Phase 2 — <name>
…

## Inputs the agent gathers upfront

Cap at ~3 questions in the first turn:

1. <input> — <why it's needed upfront>
2. <input>
3. <input>

Everything else is asked during the phase that needs it.

## Companion agents

| If… | Hand off to |
|---|---|
| <condition> | `<agent>` |

## Companion skills (cross-phase)

- `<skill>` — <when / why>.

## Anti-patterns

- **<failure mode>.** <why it's wrong, what to do instead>.

## Deliverable contract (final hand-off)

When this agent declares done, the project must have:

1. **<artifact>:** <acceptance criterion>.
2. **<artifact>:** <acceptance criterion>.

Missing any and the arc is not done.

## Reference files

- `references/<file>.md` — <what it holds>.
```

## Notes on filling it

- **`role`** is one line and persona-shaped (*"Owns the incremental-feature
  arc …"*), not a paragraph.
- **`fires_on`** uses phrases a user would actually type, plus repo-state
  triggers (e.g. *"any feature-shaped request in a project that already has
  INSTRUCTIONS/projects/<slug>/"*).
- **`skills_used.shipped`** must match real skills — verify against
  `agents/CHECKLIST.md` and the `skills/` tree. Put anything that doesn't
  exist yet under `proposed:`.
- **`deliverables`** are concrete artifacts (file paths, PRs, audits), not
  activities. "Help with X" is not a deliverable.
- **`status`** starts `draft`. Promote to `shipped` only when the dependent
  skills exist AND a SCENARIOS entry exists.
- The **Deliverable contract** section at the bottom is the numbered,
  auditable done-list — `requirement-audit` runs against it.
