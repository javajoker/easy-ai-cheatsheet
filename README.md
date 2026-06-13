# ai-claude — Claude Code skills + instructions + agents framework

A portable, project-agnostic framework for using Claude Code consistently
across many projects. It combines three content layers plus two meta
layers (maintenance and squad):

- **`claude/INSTRUCTIONS/`** — universal engineering principles and
  conventions, always loaded.
- **`claude/skills/`** — task-specific capabilities, loaded on demand when
  their descriptions match the request.
- **`claude/agents/`** — named roles that bundle a workflow, a set of
  skills, and a deliverable contract for a specific job.
- **`claude/maintenance/`** — the framework's self-tuning layer: skills that
  retune the three layers above to a new Claude model or harness version.
- **`claude/squad/`** — Squad Engineering: evaluate, organize, and dispatch
  *other* LLM products (Codex CLI, Gemini CLI, local models) under control,
  saving premium tokens for the work only Claude should do. Evaluates each
  product per *special task* (a framework skill packaged as a kit), and
  shares status/memory across members and modalities through a State
  Ledger so multi-model jobs don't compound tokens.

Everything lives under [`claude/`](claude/). Start there:

- [`claude/README.md`](claude/README.md) — framework overview, layout, counts.
- [`claude/HOWTO.md`](claude/HOWTO.md) — how to install and use it.
- [`claude/SCENARIOS.md`](claude/SCENARIOS.md) — step-by-step playbooks.

The framework is **English-first** so the model can maintain it uniformly;
each project's output (code, docs, user-facing copy) follows that project's
own primary language, declared under `claude/INSTRUCTIONS/projects/<slug>/`.
