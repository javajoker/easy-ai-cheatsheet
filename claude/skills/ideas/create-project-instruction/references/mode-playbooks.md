# Mode Playbooks

Phase-by-phase walkthroughs for each of the four input modes, with the kinds
of questions to ask and the kinds of fields to fill.

## Mode A — Existing codebase

You are invoked by `project-onboarding` or by a user with a repository in
hand.

### Phase 1 questions

- Slug: usually obvious from the repository name. Confirm if non-obvious.
- Existing instance: check `INSTRUCTIONS/projects/<slug>/` and the parent
  README's "Existing instances" table.
- Primary language: if the README is in language X, default to X for the
  output. The user can override.

### Phase 2 — gather from code

Refer to `project-onboarding/references/inference-table.md` for the
where-to-look-for-each-fact reference table. The short version:

- **Stack table** — language manifest + top-level imports.
- **Frameworks** — `package.json` dependencies, `go.mod` requires,
  `pyproject.toml` dependencies.
- **Persistence** — ORM library; `docker-compose.yml` services.
- **Verification commands** — `Makefile`, `package.json` scripts,
  `.github/workflows/*.yml`.
- **Branch + commit convention** — recent `git log --oneline -20`.

Confidence:
- **High** — explicit in a manifest or config.
- **Medium** — clear from code structure or imports.
- **Low** — guessed; ask the user.

### Phase 3 — fill

For Mode A, fields that are unlikely to be in the code:

- **Stakeholders** — `{TBD — ask the user}`.
- **Lifecycle stage** — guess from version tags + commit cadence
  (`v0.x` → MVP, no tags + heavy commits → prototype, `v1.x+` with steady
  cadence → maintenance, etc.). Mark `← inferred`.
- **Primary language for user-facing copy** — ask.

### Phase 4 — report

Highlight inferred and TBD fields prominently so the user can correct in
one pass.

## Mode B — Fresh-project conversation

You are invoked early in the lifecycle — the project does not exist as code
yet.

### Phase 1 questions

- Slug: ask. Default: kebab-cased project name.
- Existing instance: typically none, but check.
- Primary language: usually English unless the user is non-English speaking
  or the project has a specific market.

### Phase 2 — interview

Cap at 5 questions. The point is to populate a *seed* INSTRUCTIONS — not a
complete one. Many fields will be `{TBD}` and that is correct.

Targeted questions, in priority order:

1. **What is the project?** One-paragraph elevator pitch.
2. **What type?** Library, service, application, platform, data pipeline,
   research code?
3. **Stack preference?** Even just "I'm a Go shop" / "we use TypeScript
   everywhere" is enough.
4. **Primary language for user-facing copy?** English / Chinese / other.
5. **Any non-obvious constraints?** Compliance, performance, team size,
   deadline.

### Phase 3 — fill

Most of the stack table and the verification commands will be `{TBD}`. The
identity section, the languages section, and any constraints the user
volunteered will have content.

Add a section header in the generated file:

```markdown
> **Note:** this INSTRUCTIONS file was generated at project conception, before
> code existed. Many fields are `{TBD}`. They will fill in as project-docs,
> project-prototype, and the actual code work proceed.
```

### Phase 4 — report

Make the TBD count visible. The user should know this is a seed, not a
complete picture.

## Mode C — PRD + tech design

You are invoked after `project-docs` has produced PRD.md, UIUX_SPEC.md, and
TECH_DESIGN.md.

### Phase 1 questions

- Slug: from the project name in the PRD.
- Existing instance: check.
- Primary language: from `project-docs`'s i18n decisions; surface as
  default, confirm.

### Phase 2 — extract

Each section of the INSTRUCTIONS template maps cleanly to a section of the
tri-doc set:

| Template section | Source |
|---|---|
| Identity | PRD overview |
| Stack table | TECH_DESIGN stack table |
| Languages | TECH_DESIGN i18n section |
| Key conventions | TECH_DESIGN architectural decisions |
| Initialization order | TECH_DESIGN deployment / startup |
| External integrations | TECH_DESIGN integrations |
| Verification commands | TECH_DESIGN build / test commands |
| Stakeholders | PRD personas + business owners |

Most fields will be high-confidence — they were just authored in the source
docs.

### Phase 3 — fill

Straightforward template fill. Cross-check between docs for consistency; if
the PRD says "Python" and TECH_DESIGN.md says "Go," flag it and ask.

### Phase 4 — report

Highlight any inter-doc conflicts surfaced during extraction. The PRD /
UI/UX / tech design set should be self-consistent; conflicts mean an issue
upstream.

## Mode D — Hybrid

You are invoked when more than one source is in play — typically an existing
codebase plus a new PRD describing where it is headed.

### Phase 1 questions

Same as Mode A or C; also ask:

- **Which source wins for conflicts?** Common answers:
  - "Codebase wins" — we're documenting reality.
  - "PRD wins" — we're documenting the target state.
  - "Surface conflicts; I'll decide each" — slowest but safest.

### Phase 2 — gather

Run Mode A and Mode C extractions in parallel. Maintain two columns: "code
says" and "doc says." Most fields agree.

### Phase 3 — fill

For fields where sources agree: high confidence, write directly.

For fields where sources conflict:

- If user picked "code wins" or "doc wins" in Phase 1, follow that rule.
- Otherwise: write `{conflict — code: <value>, doc: <value> — pick one}` and
  surface in the report.

### Phase 4 — report

Make the conflicts visible. They are usually the most interesting findings.

## Crossing scenarios

If the user input changes mid-generation (e.g. they start in Mode B then
attach a tech design partway through), do NOT restart. Update the in-flight
generation, mark which fields gained higher confidence, and note in the
report what changed.
