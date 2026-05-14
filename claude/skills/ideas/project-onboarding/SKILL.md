---
name: project-onboarding
description: >
  Onboard an existing codebase to the Claude Code framework. Reads the
  repository, identifies the stack, language, conventions, and key components;
  generates filled instances of INSTRUCTIONS/templates/project-context.md and
  INSTRUCTIONS/templates/repository-structure.md under INSTRUCTIONS/projects/<slug>/;
  seeds a baseline of memory-ontology entries; and produces a short onboarding
  report covering "what I know" and "what I'm uncertain about". The skill is
  read-only on the source code — it does not modify the project — but writes
  to INSTRUCTIONS/projects/ and to memory/.

  USE THIS SKILL when:
  - the user opens a Claude Code session in a project for the first time
  - the user asks "onboard this project", "set up Claude Code here", "scan
    the repo and learn it", "what is this project?"
  - the user attaches an unfamiliar codebase and asks where to start
  - the user has just adopted this framework and wants to register an existing
    project under it
  - the user is starting a new working session on a project that has been
    inactive for a long time (treat as a re-onboarding pass)
  Do NOT trigger for projects already registered under INSTRUCTIONS/projects/
  unless the user explicitly says "re-onboard" or "refresh the project notes".
---

# Project Onboarding

A skill for bringing an existing codebase into the Claude Code framework
without making any code changes. The output is documentation about the
project (in `INSTRUCTIONS/projects/<slug>/`) plus durable memory entries that
let future sessions start informed.

## Why this exists

When Claude opens an unfamiliar codebase, the first ten minutes are spent
asking the user questions Claude could have answered itself — *"what
language is this in? what frameworks? what's the test command?"* — or
inferring details that are wrong and discovering them only later. Either
path wastes a session.

Onboarding consolidates that discovery into a single, structured pass:

1. Inspect the codebase systematically.
2. Capture findings in the framework's standard places.
3. Surface uncertainty explicitly so the user can correct it before it
   ossifies into a wrong assumption.

## When to fire

- First Claude Code session in a repository.
- User explicitly asks to onboard, scan, register, or set up Claude Code
  for the project.
- After a long inactive period (the project may have changed; a refresh
  pass is cheaper than a wrong assumption).

When *not* to fire:

- Project already has an entry under `INSTRUCTIONS/projects/<slug>/` with
  a recent `updated:` date. Use the existing entry; offer a refresh pass
  if the user wants one.
- The user is opening Claude Code for a one-off question and does not want
  to commit to the framework yet.

## The five-phase procedure

### Phase 1 — Surface scan

Do not read every file. Read enough to identify the shape:

- `README.md` (or `README.*`).
- `package.json`, `go.mod`, `pyproject.toml`, `pom.xml`, `Cargo.toml`,
  `Gemfile`, `composer.json` — whichever declares the language and
  dependencies.
- `CHANGELOG.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md` if present.
- The top-level directory listing.
- `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, or any other CI
  configuration.
- The presence (or absence) of `docs/`, `tests/`, `migrations/`.

Output a one-paragraph "what this looks like" assessment. Confirm it with
the user before continuing.

### Phase 2 — Stack and conventions

Now look at the source closely enough to populate the templates:

- Language version (from `go.mod`, `pyproject.toml`, `package.json`
  engines field, etc.).
- Frameworks and major libraries (top-level imports, dependency files).
- Persistence layer (search for ORM / migration tooling).
- Job queues / background processing.
- Observability stack (logging, metrics, tracing imports).
- Test runner and test layout.
- Build / deploy commands (Makefile, `scripts/` directory, package.json
  scripts).
- Branch naming and commit conventions (recent git log + CONTRIBUTING).

Note any non-standard conventions: a custom error type, a project-wide
linter config, an unusual module layout. These are exactly the things the
user shouldn't have to re-explain in every session.

### Phase 3 — Cognitive alignment with the user

Surface what you found and ask targeted questions for what you couldn't
infer:

- "I see Go 1.22, Gin, GORM, PostgreSQL, Redis — is that complete?"
- "I don't see explicit i18n — is there a locale strategy, or is this
  English-only?"
- "Tests are in `*_test.go`, integration tests are gated on
  `testing.Short()` — anything else?"
- "What primary language do you want for user-facing output: code
  comments, error messages, docs?"

Run the `cognitive-alignment` skill alongside this phase. Every term the
user uses in their answers that isn't trivially obvious becomes a candidate
library entry.

Cap at 5–7 questions in this phase. If you have more, you haven't done
Phase 2 thoroughly enough.

### Phase 4 — Generate the artifacts

**Delegate to `create-project-instruction`** in Mode A (existing codebase).
Pass forward:

- The slug.
- The gathered facts from Phase 2 with confidence levels (high / inferred /
  TBD).
- Any cognitive-library entries from Phase 3.

The delegated skill writes the files:

- `INSTRUCTIONS/projects/<slug>/project-context.md`.
- `INSTRUCTIONS/projects/<slug>/repository-structure.md`.
- `INSTRUCTIONS/projects/<slug>/conventions.md` if the project has unusual
  conventions worth capturing.
- Updates `INSTRUCTIONS/projects/README.md`'s "Existing instances" table.

If `create-project-instruction` is not loaded in the environment, fall back
to a manual fill against `INSTRUCTIONS/templates/project-context.md` and
`INSTRUCTIONS/templates/repository-structure.md`, but note the missing skill
in the Phase 6 report so the user can install it.

### Phase 5 — Seed memory

Run the `memory-ontology` skill (save operation) for the durable facts
this onboarding produced:

- One `type: project` memory per major decision or constraint surfaced
  (`scope: project:<slug>`).
- One `type: reference` memory per external system the project relies on
  (Linear project ID, Grafana dashboard, Slack channel) that the user
  mentioned.
- Any `type: user` memories that came up — "user prefers …" — go in with
  `scope: global` so they apply across projects.

Do NOT save speculation. If the user said "I think we use Redis but I'm
not sure", do not write a memory. Either confirm by reading the code or
leave it out.

### Phase 6 — Onboarding report

Surface a short report at the end:

```
Onboarded: <project name>

Stack identified:
- ...

Conventions noted:
- ...

Generated:
- INSTRUCTIONS/projects/<slug>/project-context.md
- INSTRUCTIONS/projects/<slug>/repository-structure.md
- <N> memory entries

Open questions for next session:
- ...

Suggested next step:
- ...
```

The open-questions list is critical — it's what tells the user (and a
future Claude session) where this onboarding stopped short.

## Companion skills

- `create-project-instruction` — invoked in Phase 4 to write the actual
  INSTRUCTIONS files. This skill is the *coordinator*; that one is the
  *producer*.
- `cognitive-alignment` — run continuously throughout the onboarding,
  especially Phase 3.
- `memory-ontology` — used in Phase 5; this skill is essentially a producer
  of memory entries.
- `project-knowledge-base` — natural next step if the user wants a richer
  knowledge base built from the codebase + docs, not just configuration.

## Anti-patterns

- **Asking before reading.** Read the obvious things first; only ask about
  what you genuinely cannot infer.
- **Reading too much.** Onboarding is not "understand every file." It is
  "understand the shape." Resist the urge to follow every interesting
  thread.
- **Silent assumptions.** If you guessed the test framework, mark the
  guess in Phase 4 output as "(inferred)" so the user can correct.
- **Skipping the report.** The report is what makes onboarding visible to
  the user. Without it, they don't know what just happened.

## Reference files

- `references/onboarding-checklist.md` — the literal phase-by-phase
  checklist.
- `references/inference-table.md` — what to look at in the repo to infer
  each fact you would otherwise have to ask about.
