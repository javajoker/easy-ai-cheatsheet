# Project Instances

This directory holds **filled-in instances** of the framework's portable
templates — one subdirectory per project that has been onboarded.

## Layout

```
projects/
├── README.md                   # this file
├── <project-slug>/
│   ├── project-context.md      # filled-in from templates/project-context.md
│   ├── repository-structure.md # filled-in from templates/repository-structure.md
│   ├── conventions.md          # (optional) project-specific overrides
│   └── …                       # other project notes as needed
└── …
```

## Adding a new project

The skill `project-onboarding` automates most of this:

1. Run `project-onboarding` from within the project's repository.
2. The skill reads the codebase, fills in the templates, and writes them here.
3. Review and refine the generated content with the user.
4. Reference these files from the project's own `CLAUDE.md` so they load
   when Claude opens that project.

If you are setting up manually:

1. Copy both templates from `../templates/` into a new `projects/<slug>/`.
2. Fill in every `{placeholder}`.
3. Update the project's `CLAUDE.md` to point at the new files.

## When to remove a project

When a project is archived or sunsetted:

- Move its memory entries to `status: superseded` (see `memory-ontology`).
- The instructions stay in place as historical reference; do not delete unless
  the entire project is gone from disk.

