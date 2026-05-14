# INSTRUCTIONS — portable Claude Code instructions

This directory contains the **portable, project-agnostic instructions** that
Claude Code reads when working in any project that adopts this framework. The
instructions are written in English; the artifacts Claude *produces* — code
comments, commit messages, user-facing copy — follow the **primary language of
the project being worked on**, which is declared in the project's own
`CLAUDE.md` or in `projects/<name>/`.

This separation matters: instructions are for the model and stay in one
language so they are easy to maintain. Output is for the humans using the
project and follows their context.

## What lives here

```
INSTRUCTIONS/
├── README.md                       # this file
├── development-principles.md       # universal engineering principles
├── claude-code-best-practices.md   # generic Claude Code workflow guidance
├── markdown-conventions.md         # default markdown formatting and front matter
├── standards/
│   ├── code-standards.md           # language-agnostic code principles, with per-language pointers
│   ├── document-standards.md       # brief doc-conventions reference
│   └── testing-standards.md        # universal testing principles
├── workflows/
│   ├── git-workflow.md             # branching and commit conventions
│   └── task-management.md          # task planning and progress tracking
├── templates/                      # placeholders projects copy-and-fill
│   ├── project-context.md
│   └── repository-structure.md
└── projects/                       # filled-in instances for specific projects
    ├── README.md
    ├── stardust/                   # example: a Go base library
    └── coolshell/                  # example: an AI-pattern customization platform
```

## How Claude uses this

| When Claude is doing... | Read first |
|---|---|
| Generic engineering question on any project | `development-principles.md` |
| Following Claude Code workflow patterns (plan-mode, /clear, subagents) | `claude-code-best-practices.md` |
| Writing or editing markdown | `markdown-conventions.md` + `standards/document-standards.md` |
| Code work in a known language | `standards/code-standards.md` + the relevant `skills/dev-<language>/` |
| Writing or running tests | `standards/testing-standards.md` |
| Branching, committing, merging | `workflows/git-workflow.md` |
| Planning tasks for a multi-step request | `workflows/task-management.md` |
| Working in a specific project that has been onboarded | `projects/<name>/` + the project's own `CLAUDE.md` |
| Starting a new project from scratch | copy `templates/` into the new project, fill in placeholders |

## Adding a new project

1. Copy `templates/project-context.md` and `templates/repository-structure.md`
   into `projects/<your-project>/`.
2. Fill in the placeholders (project name, language, module path, top-level
   directory layout, key conventions).
3. Reference the new project from the project's own `CLAUDE.md` at the
   project root.
4. If the project introduces patterns worth keeping (e.g. a custom test
   runner, a non-standard module layout, a specific i18n approach), add a
   `projects/<name>/conventions.md` describing them.

The skill `project-onboarding` automates most of this for an existing
codebase.

## Adding a new instruction (portable)

If you find yourself writing the same engineering guidance in two different
project notes, it probably belongs here, not there. Pull it up:

1. Add a new top-level `.md` or extend an existing one in `standards/` or
   `workflows/`.
2. Update this README's "What lives here" section.
3. Run the audit step of the `memory-ontology` skill so any related memories
   pick up the new pointer.

## Adding a new skill

Skills live in `../skills/`, not in `INSTRUCTIONS/`. The boundary:

- **Instructions** describe *how to do work* — principles, conventions,
  workflows. Always loaded.
- **Skills** describe *how to do a specific task* — they ship with reference
  files, scripts, and templates, and only load when the task triggers them.

If the new artifact has executable scripts, large reference docs, or trigger
phrases that should activate it on demand, it is a skill. If it is a few
paragraphs of always-applicable guidance, it is an instruction.

## Language policy

- **This directory is English.** Instructions, skill SKILL.md files, and
  reference docs are written in English so they are uniformly maintainable.
- **Project output follows the project's primary language.** Code comments,
  commit messages, error strings, and user-facing copy are in whatever
  language the project's `CLAUDE.md` or `projects/<name>/` declares (English,
  Traditional Chinese, Japanese, Spanish, etc.).
- **Conversations with the user follow the user's language.** See
  `skills/share/cognitive-alignment/` — restate moves, library entries, and
  profile entries are in the user's language. The instructions are for
  Claude; the conversation is for the user.

Configure your project's primary language in its own `CLAUDE.md` and in the
`projects/<name>/project-context.md` instance.

## Versioning

Each instruction file declares its own version at the bottom. When you update
guidance:

1. Bump the version on the file.
2. Update the `updated:` date.
3. If the change affects a workflow currently in flight on any project, surface
   the change to the user (do not silently start applying new guidance).
