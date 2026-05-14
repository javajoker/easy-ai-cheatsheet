# Onboarding Checklist

A copy-pasteable phase-by-phase checklist. Use during the onboarding pass to
keep track of what has been done.

## Phase 1 — Surface scan

```
[ ] Read README.md (or equivalent)
[ ] Read top-level directory listing
[ ] Read the language manifest file:
    [ ] go.mod
    [ ] package.json
    [ ] pyproject.toml / setup.cfg
    [ ] Cargo.toml
    [ ] pom.xml / build.gradle
    [ ] (other: ___)
[ ] Read CONTRIBUTING.md / CODE_OF_CONDUCT.md / CHANGELOG.md if present
[ ] Read CI config: .github/workflows/, .gitlab-ci.yml, Jenkinsfile
[ ] Note presence of docs/, tests/, migrations/, scripts/
[ ] Write one-paragraph "what this looks like" assessment
[ ] Confirm assessment with user before continuing
```

## Phase 2 — Stack and conventions

```
[ ] Language version
[ ] Web framework
[ ] ORM / data access pattern
[ ] Database choices
[ ] Cache / KV store
[ ] Queue / event bus
[ ] Observability (logger, metrics, tracing)
[ ] Test runner and test layout
[ ] Build commands (Makefile, package.json scripts, etc.)
[ ] Deploy target (Docker, Kubernetes, serverless, traditional)
[ ] Branch naming convention (sample git log)
[ ] Commit message convention (sample git log)
[ ] Non-standard conventions to capture
```

## Phase 3 — Cognitive alignment

```
[ ] Confirm stack list with user (one consolidated question)
[ ] Ask about anything Phase 2 could not infer (cap at 5-7 questions total)
[ ] Capture each load-bearing term in the cognitive library
```

Targeted question examples:

- "Is the stack list above complete?"
- "What language do you want for user-facing copy (errors, comments, docs)?"
- "Which i18n locales are in scope?"
- "Is there a custom error type or logging wrapper I should know about?"
- "Are there project rules that aren't in CONTRIBUTING — anything you have
  to keep re-explaining to new engineers?"

## Phase 4 — Generate artifacts

```
[ ] Fill in INSTRUCTIONS/projects/<slug>/project-context.md from template
    [ ] Identity section
    [ ] Stack table
    [ ] Languages section
    [ ] Key conventions
    [ ] Initialization order (if non-obvious)
    [ ] External integrations
    [ ] Verification commands
[ ] Fill in INSTRUCTIONS/projects/<slug>/repository-structure.md from template
    [ ] Top-level layout
    [ ] Source code organization
    [ ] Documentation layout
    [ ] Where-things-go reference
[ ] Optional: conventions.md if project has notable rules beyond the standards
[ ] Update INSTRUCTIONS/projects/README.md "Existing instances" table
```

## Phase 5 — Seed memory

```
[ ] type: project memory for each major decision or constraint
    (scope: project:<slug>)
[ ] type: reference memory for each external system mentioned
[ ] type: user memory for user preferences that came up (scope: global)
[ ] Add MEMORY.md index entries
[ ] Verify with memory-ontology audit operation
```

## Phase 6 — Onboarding report

```
[ ] Summarize stack identified
[ ] Summarize conventions noted
[ ] List artifacts generated
[ ] List open questions (what was not resolved)
[ ] Suggest a next step
```
