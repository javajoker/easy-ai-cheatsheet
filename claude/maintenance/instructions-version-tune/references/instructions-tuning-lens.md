# Instructions Tuning Lens

The INSTRUCTIONS analogue of the dispatcher's capability → shape-change map.
Two parts: a **per-file version-sensitivity ranking** (where to look), and a
**capability → instruction-change mapping** (what to propose). The
portable-vs-project-override decision runs through both.

> Reminder: INSTRUCTIONS are **always-loaded** and **portable across every
> project**. A finding must be true across stacks. If it only helps one
> stack, it is a project override, not a portable-INSTRUCTIONS tune.

## Per-file version sensitivity

Verify the actual file set against the live `INSTRUCTIONS/` tree before
tuning — this ranking reflects the framework's portable files.

| File | Sensitivity | Why |
|---|---|---|
| `claude-code-best-practices.md` | **High** | Direct guidance on using the harness. Predating subagents / plan mode / background tasks / compaction / Skills / MCP / worktrees makes it stale by definition. The primary target. |
| `development-principles.md` | **Medium** | May encode defensive context budgeting or manual step-chaining shaped by older model limits. |
| `workflows/task-management.md` | **Medium** | Step-by-step rituals the model may now do in one pass; could lean on harness task/background mechanics. |
| `README.md` (INSTRUCTIONS) | **Low–Med** | Mostly structural; tune only if it describes capabilities. |
| `standards/code-standards.md`, `standards/testing-standards.md`, `standards/document-standards.md` | **Low** | A coding/testing/doc standard is version-neutral unless it explicitly reasons about model behaviour. |
| `markdown-conventions.md`, `workflows/git-workflow.md` | **Low** | Conventions independent of model/harness version. |
| `templates/*`, `projects/*` | **N/A (project layer)** | Project-specific; not portable-INSTRUCTIONS tuning. Changes here are project work, not a version tune. |

Start at High, descend only as far as real findings justify. Most tunes at
this layer touch `claude-code-best-practices.md` and stop.

## Capability → instruction-change mapping

| If an INSTRUCTIONS file currently… | …and the version offers… | …propose (kind) |
|---|---|---|
| Never mentions delegating fan-out work | Subagents (harness, `confirmed`) | Add best-practice guidance: delegate broad searches / multi-step sub-jobs to subagents above a size threshold (`procedure`/`reference`) |
| Has no checkpoint guidance for risky changes | Plan mode (harness, `confirmed`) | Add: gate large/irreversible work behind plan mode (`procedure`/`reference`) |
| Says "keep working context minimal / outputs short" as a principle | Larger window + compaction (harness `confirmed` / model `inferred`) | Relax to "lean on compaction; cross-link `compact-ritual`" — relax, don't delete discipline (`procedure`/`wiring`) |
| Prescribes a manual multi-step ritual the model can now do in one pass | Stronger single-pass reasoning (model, `inferred`, directional) | Collapse the ritual conservatively; name the release-note dependency (`procedure`) |
| Tells the model to run independent steps one at a time | Parallel tool calls (harness, `confirmed`) | Add: batch independent tool calls (`procedure`) |
| Has no guidance on persisting durable facts | Memory store + `memory-ontology` (harness, `confirmed`) | Add a pointer to `memory-ontology` for cross-session facts (`wiring`) |
| Carries "the model cannot reliably do Z" | A version that made Z reliable | Retire the workaround caveat; cite the release note if `inferred` (`anti-pattern`) |
| Doesn't mention the Skill / MCP systems as composition tools | Skill + MCP systems (harness, `confirmed`) | Add: prefer composing an existing skill / MCP tool over hand-rolling (`reference`/`wiring`) |

## The portable-vs-project-override decision

For every candidate finding, before writing a proposal, run this gate:

```
Is the change true for EVERY project that loads these INSTRUCTIONS?
  ├── Yes → portable-INSTRUCTIONS tune (this skill; proposal targets
  │         INSTRUCTIONS/<path>.md)
  └── No / only-this-stack → project override
            (INSTRUCTIONS/projects/<slug>/…; NOT a portable tune)
```

See `skill-evolution/references/override-vs-evolution.md` for the override
mechanism. Getting this wrong is the highest-cost mistake at this layer: a
stack-specific change promoted into portable INSTRUCTIONS degrades every
other project's always-loaded guidance.

## Blast radius in Risks

Because the file is always-loaded, every proposal's **Risks** section names
the cross-project blast radius explicitly:

- Which project types could this change *weaken* even as it helps others?
- Does it assume a stack/tool not every project has?
- Is the capability it relies on `(inferred)` — and thus the guidance
  conditional on a release-note confirmation?

"No known risks" on a portable-INSTRUCTIONS change is a signal to think
harder, not a valid entry.
