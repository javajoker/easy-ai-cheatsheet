# ai-claude — Claude Code skills + instructions + agents framework

A portable, project-agnostic framework for using Claude Code consistently
across many projects. It combines three layers:

- **`claude/INSTRUCTIONS/`** — universal engineering principles and
  conventions, always loaded.
- **`claude/skills/`** — task-specific capabilities, loaded on demand when
  their descriptions match the request.
- **`claude/agents/`** — named roles that bundle a workflow, a set of
  skills, and a deliverable contract for a specific job.

Everything lives under [`claude/`](claude/). Start there:

- [`claude/README.md`](claude/README.md) — framework overview, layout, counts.
- [`claude/HOWTO.md`](claude/HOWTO.md) — how to install and use it.
- [`claude/SCENARIOS.md`](claude/SCENARIOS.md) — step-by-step playbooks.

The framework is **English-first** so the model can maintain it uniformly;
each project's output (code, docs, user-facing copy) follows that project's
own primary language, declared under `claude/INSTRUCTIONS/projects/<slug>/`.
