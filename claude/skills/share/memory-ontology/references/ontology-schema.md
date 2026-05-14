# Memory ontology — schema reference

The full frontmatter contract for memory files, the valid values for each
field, and the semantics of every relation.

## Frontmatter fields

| Field | Required | Default | Notes |
|---|---|---|---|
| `name` | yes | — | Short title, also used as the H1 if needed. |
| `description` | yes | — | One-line description. Used for relevance matching by future sessions. Be specific — generic descriptions cause false positives. |
| `type` | yes | — | `user`, `feedback`, `project`, or `reference`. See type rules below. |
| `scope` | no | `global` | `global`, `project:<slug>`, or `session`. Determines which projects load this memory. |
| `created` | yes | — | ISO date `YYYY-MM-DD`. Set once, never modified. |
| `updated` | no | — | ISO date. Bump on refinement, not on supersession. |
| `status` | no | `active` | `active`, `tentative`, `superseded`. |
| `supersedes` | no | — | Filename of the prior memory this one replaces. |
| `superseded-by` | no | — | Filename of the memory that replaces this one. |
| `related` | no | `[]` | List of filenames. Bidirectional. |
| `applies-to` | no | `[]` | List of entities this memory governs. Free-form but conventional: `project:<slug>`, `domain:<area>`, `tool:<name>`. |
| `distinct-from` | no | `[]` | List of filenames. Used to prevent future conflation. |

## Type rules

### `type: user`

About the person — role, expertise, preferences, working style, languages they
speak. The rule of thumb: if it would still be true if the user changed jobs,
it is a user memory.

`scope` is almost always `global`. A `project`-scoped user memory is unusual
(e.g., "uses a different display name on this project"); prefer global where
possible.

### `type: feedback`

Guidance about *how* Claude should work — corrections and validated approaches.
The rule of thumb: if it answers *"how should I act?"*, it is feedback.

Body must include:

- **Why** — the reason the user gave, often a past incident.
- **How to apply** — the situations the rule fires in.

Without these, the rule cannot be applied to edge cases — it becomes a blunt
constraint.

### `type: project`

About a specific project's situation — ongoing work, goals, incidents,
decisions, deadlines, stakeholders.

`scope: project:<slug>` is the default. A `global` project memory is a bug —
move it to the right project scope.

Body must include:

- **Why** — the constraint or motivation behind the fact.
- **How to apply** — how the fact should shape suggestions.

Project memories decay fastest. Stamp `updated:` on any refinement so audit
passes can catch stale entries.

### `type: reference`

Pointers to external systems — dashboards, ticket trackers, chat channels,
runbooks.

Body is typically two parts: *where* (URL / system / project name) and *what
for* (when to consult it). Keep it short.

## Relation semantics

### `supersedes` / `superseded-by`

A directed pair. If `B.supersedes = A`, then `A.superseded-by` MUST be `B` and
`A.status` MUST be `superseded`.

Both files survive. The chain is the record of how the memory evolved.

### `related`

Symmetric. If `A.related` includes `B`, then `B.related` SHOULD include `A`. An
auditor repairs missing back-edges.

Used for "see also" relations — same topic, complementary perspective, etc. —
that are not strong enough to be a supersession.

### `applies-to`

Directed from memory to entity. The entity is not necessarily another memory.
Common shapes:

- `project:<slug>` — project this memory governs.
- `domain:<area>` — broad topic, e.g. `domain:testing`, `domain:database`.
- `tool:<name>` — specific tool, e.g. `tool:git`, `tool:claude-code`.
- `lifecycle:<phase>` — `lifecycle:onboarding`, `lifecycle:release`.

### `distinct-from`

Symmetric. Used between memories with similar names or topics that should
*not* be conflated. Same use case as `distinct-from` in the cognitive library.

## Status semantics

- **`active`** — currently in effect. The default.
- **`tentative`** — saved on Claude's initiative without explicit user
  confirmation. The user should confirm at the next natural moment.
- **`superseded`** — replaced by another memory. Kept on disk; moved to the
  archive sub-section in `MEMORY.md`.

A `tentative` memory should be visibly different in `MEMORY.md` (suffix it
` ⚠ tentative`) so the user can see what is awaiting confirmation.

## Conventions

- **Filenames** — snake_case, prefixed by type: `user_role.md`,
  `feedback_pr_size.md`, `project_coolshell_freeze.md`,
  `reference_linear.md`. Prefix makes glob queries easy.
- **One memory per file.** Compound memories drift apart and become hard to
  supersede individually.
- **Dates in body, not just frontmatter.** If a memory references a date
  (release, deadline, incident), state it absolutely in the body too.
- **No emojis in memory bodies.** Plain text survives compaction better. The
  one exception: a `⚠ tentative` marker in `MEMORY.md` after the entry name.
