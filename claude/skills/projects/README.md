# Project-specific skills

This directory holds **project-specific skills** — skills that only apply when
the user is working inside one specific project (or family of projects). They
are kept here, separate from the portable skill categories (`dev-go/`,
`design/`, `ideas/`, etc.), so that the portable surface stays clean.

## Layout

```
projects/
├── README.md           # this file
├── <project-slug>/     # one directory per project that has a skill
│   ├── SKILL.md
│   ├── references/
│   ├── scripts/
│   └── assets/
└── …
```

## Naming convention

The skill `name:` field in the SKILL.md should use the same slug as the
project directory, with a suffix that describes what kind of reference the
skill provides. Common suffixes:

- `-rtl` — runtime library, the project's internal API surface.
- `-conventions` — project-specific style or layout rules beyond what the
  portable skills cover.
- `-runbook` — operational procedures specific to the project.

Examples:

- `stardust-rtl` — the stardust Go microservice library's API.
- `coolshell-conventions` — coolshell's WeChat miniprogram-specific
  patterns.

## Companion INSTRUCTIONS

Each project-specific skill typically pairs with an
`INSTRUCTIONS/projects/<slug>/` directory holding the project-context.md and
repository-structure.md files. The `project-onboarding` skill produces both
sides of this pairing.

## Language policy

- **SKILL.md** — English (framework-discoverable surface).
- **`references/`** — project's primary language (project-language artifacts
  policy).

If a project's primary language is non-English, expect the references to be
in that language. The SKILL.md description should note this so users in
mixed-language environments are not surprised.

## When to create a new entry

Add a project-specific skill when:

- The project has a substantial internal API surface (more than a couple of
  packages) that downstream code repeatedly looks up.
- The project's conventions deviate enough from the portable defaults that
  the generic dev skills produce wrong output.
- The project has operational quirks (release process, deployment
  procedure) that benefit from a dedicated runbook skill.

Do *not* create one when:

- The project follows the framework defaults — universal instructions are
  enough.
- The "specifics" are really just a handful of style preferences — capture
  those in `INSTRUCTIONS/projects/<slug>/conventions.md` instead.

