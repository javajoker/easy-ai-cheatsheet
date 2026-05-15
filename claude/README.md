# ai-claude — Claude Code skills + instructions framework

A portable, project-agnostic framework for using Claude Code consistently across
many projects. It combines two layers:

- **`INSTRUCTIONS/`** — universal engineering principles and conventions
  always loaded by Claude.
- **`skills/`** — task-specific capabilities loaded on demand by Claude when
  their triggers fire.

The framework is **English-first** so the model can maintain it uniformly.
Project output (code, docs, user-facing copy, conversational restate phrases)
follows the **primary language of each project**, declared per-project under
`INSTRUCTIONS/projects/<slug>/`.

## Layout

```
claude/
├── README.md                       # this file
├── HOWTO.md                        # how to use the framework
├── SCENARIOS.md                    # workflow playbooks with checklists
├── INSTRUCTIONS/                   # portable instructions (always loaded)
│   ├── README.md
│   ├── development-principles.md   # universal engineering principles
│   ├── claude-code-best-practices.md
│   ├── markdown-conventions.md
│   ├── standards/                  # code, doc, testing standards
│   ├── workflows/                  # git, task management
│   ├── templates/                  # per-project template files
│   └── projects/                   # filled instances for specific projects
└── skills/
    ├── share/                      # cross-cutting meta-skills
    │   ├── skill-orchestrator/     # picks and chains skills for multi-step tasks
    │   ├── cognitive-alignment/    # shared meaning between Claude and user
    │   ├── memory-ontology/        # durable MEMORY graph across sessions
    │   ├── compact-ritual/         # /compact survival procedure
    │   ├── requirement-audit/      # PASS/PARTIAL/FAIL checklist of a multi-point ask
    │   ├── scenario-checklist/     # produces the "Skills involved" table for a workflow
    │   ├── skill-evolution/        # captures live-use evolution candidates as proposals
    │   └── skill-merge/            # applies accepted proposals with conflict detection
    ├── ideas/                      # project lifecycle (11 skills)
    │   ├── README.md               # the project quick-start narrative
    │   ├── WORKFLOW.md             # detailed phase-by-phase walkthrough
    │   ├── project-prototype/
    │   ├── project-docs/
    │   ├── project-mockup-app/
    │   ├── task-breakdown/
    │   ├── project-frontend/
    │   ├── project-backend-node/
    │   ├── project-backend-go/
    │   ├── project-backend-python/
    │   ├── project-onboarding/     # bring an existing codebase into the framework
    │   ├── project-knowledge-base/ # conceptual knowledge graph of a project
    │   └── create-project-instruction/  # focused producer for INSTRUCTIONS/projects/<slug>/
    ├── dev-go/                     # 20 Go style and quality skills (portable)
    ├── dev-node/                   # 20 Node.js / TypeScript skills (portable)
    ├── dev-python/                 # 20 Python style and quality skills (portable)
    ├── dev-java/                   # 20 Java style and quality skills (portable)
    ├── dev-tools/                  # ccc (semantic search), doc-markdown-standards, omc-reference
    ├── design/                     # ui-ux-pro-max
    ├── knowledge-graph/            # book / long-text → ontology pipeline (6 skills)
    └── projects/                   # project-specific skills (e.g. stardust-rtl)
```

## Counts

| Group | Skills |
|---|---|
| `share/` | 8 |
| `ideas/` | 11 |
| `dev-go/` | 20 |
| `dev-node/` | 20 |
| `dev-python/` | 20 |
| `dev-java/` | 20 |
| `dev-tools/` | 3 |
| `design/` | 1 |
| `knowledge-graph/` | 6 |
| `projects/` | 1 |
| **Total** | **110** |

Plus 13 portable instruction files under `INSTRUCTIONS/` and 2 templates.
The top-level `REQUIREMENTS-AUDIT.md` records the verified completion of
the framework-consolidation request that produced this revision.

## Three principles the framework enforces

1. **English instructions, project-language artifacts.** The model reads one
   language; users get output in their own.
2. **Cognitive alignment runs alongside every workflow.** The
   `cognitive-alignment`, `memory-ontology`, and `compact-ritual` skills
   together keep shared meaning intact across turns, across `/compact`, and
   across sessions.
3. **Skills are discoverable through descriptions, orchestrated through
   `skill-orchestrator`.** No skill is hard-coded into a workflow; the
   orchestrator picks chains from descriptions at runtime.

## Quick links

- **First time using this?** See [HOWTO.md](HOWTO.md).
- **Want a step-by-step playbook for a common situation?** See
  [SCENARIOS.md](SCENARIOS.md).
- **Onboarding an existing project?** Run the `project-onboarding` skill.
- **Starting a new project from an idea?** Run the `project-prototype`
  skill — it kicks off the eight-skill linear chain.
- **Where do durable user preferences live?** See `skills/share/memory-ontology/`.
- **Before `/compact`?** See `skills/share/compact-ritual/`.
- **Verifying a multi-point request was actually delivered?** Run
  `requirement-audit`; the audit format is in
  [REQUIREMENTS-AUDIT.md](REQUIREMENTS-AUDIT.md).
- **Adding a new scenario or asking what skills a workflow will use?**
  Run `scenario-checklist`.
- **Captured a "this skill should be sharper" observation during live
  work?** Run `skill-evolution` to write a proposal, then `skill-merge`
  to apply it when ready. See `HOWTO.md` "Evolving a skill through use".

## What changed in this revision

This framework was consolidated to remove conflicts and gaps. See
[the SCENARIOS doc's appendix](SCENARIOS.md#appendix-checklists) for the
full audit summary. Key changes:

- INSTRUCTIONS rewritten to portable English; project-specifics moved to
  `INSTRUCTIONS/projects/<slug>/`.
- `cognitive-alignment` consolidated (the bilingual variant was folded in).
- Two new shared meta-skills: `memory-ontology` and `compact-ritual`.
- `skills/ontology/` renamed to `skills/knowledge-graph/` to disambiguate
  from the MEMORY ontology.
- Three new project skills: `project-onboarding`, `project-knowledge-base`,
  and `create-project-instruction` (the focused INSTRUCTIONS producer).
- The Chinese-language `go-stardust-rtl` skill was moved out of the portable
  `skills/dev-go/` namespace into a new `skills/projects/` namespace as
  `stardust-rtl`, marked as an example of a project-specific skill produced
  through onboarding.
- Two new audit / checklist meta-skills under `share/`: `requirement-audit`
  (verifies a numbered requirements list with PASS/PARTIAL/FAIL evidence)
  and `scenario-checklist` (produces the "Skills involved" table for any
  workflow).
- Two new evolution meta-skills under `share/`: `skill-evolution`
  (captures evolution candidates during live use as reviewable proposals)
  and `skill-merge` (applies accepted proposals with conflict detection
  and downstream consistency checks). Together they form the observe →
  propose → merge loop so the framework can sharpen itself through use
  without silent file rewrites.
- All cross-cutting workflows documented in `SCENARIOS.md` with checklists,
  including Scenario K (framework self-audit) and Scenario L (evolving a
  skill through live project use).
- `REQUIREMENTS-AUDIT.md` at the framework root records the explicit
  verification that the framework-consolidation request was satisfied
  end-to-end.

## License and authorship

See individual skill SKILL.md files for license metadata where applicable.
The `dev-go/*`, `dev-node/*`, `dev-python/*`, and `dev-java/*` skills derive
from public language style guides; per-skill attributions are in their own
frontmatter.
