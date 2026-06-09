# ai-claude — Claude Code skills + instructions + agents framework

A portable, project-agnostic framework for using Claude Code consistently across
many projects. It combines three layers:

- **`INSTRUCTIONS/`** — universal engineering principles and conventions
  always loaded by Claude.
- **`skills/`** — task-specific capabilities loaded on demand by Claude when
  their triggers fire.
- **`agents/`** — named roles that bundle a workflow, a set of skills, and a
  deliverable contract for a specific job (lifecycle, architecture upgrade,
  scenario strategy, devops, enterprise knowledge base, feature development).

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
├── agents/                         # named roles that compose skills + workflow
│   ├── README.md                   # what agents are; how they relate to skills
│   ├── CHECKLIST.md                # build status of all agents + dependent skills
│   ├── lifecycle-pilot/            # prototype → prod → go-to-market
│   ├── architecture-shepherd/      # architecture upgrade support
│   ├── scenario-strategist/        # scenario analysis + workflow + group formation
│   ├── devops-engineer/            # CI/CD, IaC, observability, runbooks, secrets
│   ├── knowledge-curator/          # enterprise knowledge base upgrade
│   └── feature-development/        # add a feature to an onboarded project
└── skills/
    ├── share/                      # cross-cutting meta-skills
    │   ├── skill-orchestrator/     # picks and chains skills for multi-step tasks
    │   ├── cognitive-alignment/    # shared meaning between Claude and user
    │   ├── memory-ontology/        # durable MEMORY graph across sessions
    │   ├── compact-ritual/         # /compact survival procedure
    │   ├── requirement-audit/      # PASS/PARTIAL/FAIL checklist of a multi-point ask
    │   ├── scenario-checklist/     # produces the "Skills involved" table for a workflow
    │   ├── skill-evolution/        # captures live-use evolution candidates as proposals
    │   ├── skill-merge/            # applies accepted proposals with conflict detection
    │   ├── skill-version-tune/     # retunes a skill for a model/harness version (dispatcher)
    │   ├── agent-version-tune/     # retunes an agent (AGENT.md) for a version (dispatcher)
    │   ├── instructions-version-tune/  # retunes an INSTRUCTIONS file for a version (dispatcher)
    │   ├── agent-create/           # scaffolds + registers a new agent
    │   ├── tune-for-opus-4-6/      # Opus 4.6 capability lens (shared worker)
    │   ├── tune-for-opus-4-7/      # Opus 4.7 capability lens (shared worker)
    │   ├── tune-for-opus-4-8/      # Opus 4.8 capability lens (shared worker)
    │   └── tune-for-cc-harness/    # current CC harness capability lens (shared worker)
    ├── ideas/                      # project lifecycle (12 skills)
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
    │   ├── create-project-instruction/  # focused producer for INSTRUCTIONS/projects/<slug>/
    │   └── feature-spec/           # single-feature delta spec for an onboarded project
    ├── dev-go/                     # 20 Go style and quality skills (portable)
    ├── dev-node/                   # 20 Node.js / TypeScript skills (portable)
    ├── dev-python/                 # 20 Python style and quality skills (portable)
    ├── dev-java/                   # 20 Java style and quality skills (portable)
    ├── dev-tools/                  # ccc (semantic search), doc-markdown-standards, omc-reference
    ├── design/                     # ui-ux-pro-max
    ├── knowledge-graph/            # book / long-text → ontology pipeline (6 skills)
    ├── gtm/                        # go-to-market skills (lifecycle-pilot — 6)
    ├── architecture/               # architecture upgrade skills (architecture-shepherd — 5)
    ├── scenario/                   # scenario / workflow / group formation skills (scenario-strategist — 4)
    ├── devops/                     # devops skills (devops-engineer — 7)
    └── enterprise-kb/              # enterprise KB skills (knowledge-curator — 5)
```

Project-specific skills (skills that only apply inside one project) live
under `skills/projects/<slug>/`, created on demand — see HOWTO.md
"Per-project skills". None ship with the framework.

## Counts

| Group | Skills |
|---|---|
| `share/` | 16 |
| `ideas/` | 12 |
| `dev-go/` | 20 |
| `dev-node/` | 20 |
| `dev-python/` | 20 |
| `dev-java/` | 20 |
| `dev-tools/` | 3 |
| `design/` | 1 |
| `knowledge-graph/` | 6 |
| `gtm/` | 6 |
| `architecture/` | 5 |
| `scenario/` | 4 |
| `devops/` | 7 |
| `enterprise-kb/` | 5 |
| **Total** | **145** (all shipped) |

| Agents | Count |
|---|---|
| `agents/` | 6 |

Plus 13 portable instruction files under `INSTRUCTIONS/` and 2 templates.

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
  [SCENARIOS.md](SCENARIOS.md) — 21 scenarios plus two fully worked
  end-to-end examples (onboarding a project, and adding a feature).
- **Which agents own which jobs?** See [agents/README.md](agents/README.md).
- **Current build status of agents + new skills?** See
  [agents/CHECKLIST.md](agents/CHECKLIST.md).
- **Onboarding an existing project?** Run the `project-onboarding` skill.
- **Starting a new project from an idea?** Run the `project-prototype`
  skill — it kicks off the eight-skill linear chain.
- **Where do durable user preferences live?** See `skills/share/memory-ontology/`.
- **Before `/compact`?** See `skills/share/compact-ritual/`.
- **Verifying a multi-point request was actually delivered?** Run
  `requirement-audit`; the audit format is in
  `skills/share/requirement-audit/references/audit-template.md`.
- **Adding a new scenario or asking what skills a workflow will use?**
  Run `scenario-checklist`.
- **Captured a "this skill should be sharper" observation during live
  work?** Run `skill-evolution` to write a proposal, then `skill-merge`
  to apply it when ready. See `HOWTO.md` "Evolving a skill through use".

## Keeping the framework alive

The framework does not rewrite itself silently, but it has two
human-checkpointed loops for staying current:

- **Evolution loop** (failure-driven). When live work shows a skill could be
  sharper, `skill-evolution` captures a reviewable proposal and `skill-merge`
  applies it after you approve the diff. See HOWTO.md "Evolving a skill
  through use" and SCENARIOS.md Scenario L.
- **Version-tuning family** (capability-driven). When a new Claude model or
  Claude Code harness version lands, the `*-version-tune` dispatchers walk a
  layer against per-version capability sheets and emit the same kind of
  proposals. See HOWTO.md "Updating a skill, agent, or instructions for a new
  model or harness version" and SCENARIOS.md Scenario U.

## License and authorship

See individual skill SKILL.md files for license metadata where applicable.
The `dev-go/*`, `dev-node/*`, `dev-python/*`, and `dev-java/*` skills derive
from public language style guides; per-skill attributions are in their own
frontmatter.
