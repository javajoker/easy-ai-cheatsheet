# Extraction Guide — finding good entities

How to identify good entity candidates in different language ecosystems. The
goal is **20–80 entities** for a typical project: granular enough to be
useful, coarse enough to stay maintainable.

## Across all languages

### Features

Cluster routes, queue consumers, and CLI commands by purpose. Each coherent
cluster is a feature.

| Cluster signal | Feature |
|---|---|
| 3+ routes under `/auth/*` | `feature-auth` |
| 2+ workers under `notifications.*` queue | `feature-notifications` |
| CLI commands `seed`, `migrate`, `backup` | `feature-data-ops` |

A feature is *not* a CRUD form. "Create user, read user, update user, delete
user" is one feature ("user management"), not four.

### Modules

A module is a coherent code unit — package, namespace, directory — that
owns one or more features. A good module entity has:

- An obvious top-level directory or namespace.
- Public surface that other modules depend on.
- A clear single-sentence description.

A `util/` or `helpers/` directory is *not* a module; it is a junk drawer.
Either decompose it into real modules or leave it out.

### Services

A service is a deployable unit. Heuristics:

- Has its own entry point (`main`, `wsgi.py`, `index.ts`).
- Has its own Dockerfile or its own line in `docker-compose.yml`.
- Has its own deployment target in CI.

### Abstractions

An abstraction crosses many call sites. Heuristics:

- Defined as an `interface` (Go), `Protocol` / ABC (Python), abstract class
  (Java/C#), `type` with multiple implementers (TypeScript).
- Referenced from 5+ files.
- Tests use a fake / mock implementation of it.

A type defined and used only inside one file is not an abstraction.

### Externals

Every external SDK import is a candidate `external` entity. Group by vendor:
`stripe`, `sendgrid`, `s3`, `linear`, `slack`. Even small integrations get an
entity because they are a stable failure surface.

### Roles

For applications with users, every distinct role gets an entity:
`user-anonymous`, `user-authenticated`, `merchant`, `admin`,
`service-account`. The role hierarchy and permissions belong in the body of
the role entity.

### Decisions

Look in `docs/decisions/`, `docs/architecture-decisions/`, ADR-style files,
and CHANGELOG entries marked "BREAKING CHANGE" or "RFC". Each is a candidate
`decision` entity. The body captures the rationale; the `related` block
captures what the decision constrains.

### Terms

Three sources, in priority order:

1. Cognitive library entries from prior sessions on this project (see
   `cognitive-alignment` skill).
2. Project-specific words in code comments or commit messages that recur and
   that would confuse a new engineer.
3. Domain vocabulary in README and design docs that isn't standard English /
   target-language vocabulary.

A `term` entity body always includes:

- The project-specific meaning.
- An example of correct usage.
- Distinct-from entries for terms it might be confused with.

## Per-language hints

### Go

- Top-level packages under `internal/` and `pkg/` → likely `module` entities.
- Interfaces defined in `interfaces.go` or `<concept>.go` → likely
  `abstraction` entities.
- `cmd/*` subdirectories → likely `service` entities.
- Test packages with a `_test` suffix → not entities; they reference the
  module they test.

### Python

- Top-level packages under `app/` or `src/<project>/` → likely `module`
  entities.
- Protocol classes and ABCs → likely `abstraction` entities.
- `manage.py` commands → CLI features.
- Celery / arq tasks → queue features.

### TypeScript / Node.js

- Top-level dirs under `src/` (e.g. `src/auth/`, `src/payments/`) → likely
  `module` entities.
- Exported types with `interface` / `type` declarations referenced widely →
  candidate `abstraction` entities.
- Express / Fastify routers → feature clusters.
- BullMQ workers → queue features.

### Rust

- Top-level crates and modules → likely `module` entities.
- Traits referenced widely → likely `abstraction` entities.
- Binaries declared in `[[bin]]` → likely `service` entities.

### Polyglot projects

Each language layer (frontend, backend, mobile, infra) typically gets its
own set of entities. Cross-language relations (`exposes`, `consumes`) link
them. The `service` entities are the natural join points.

## Anti-patterns

- **One entity per file.** Files are an implementation detail. Concepts are
  the entities.
- **One entity per route.** Routes are part of a feature; many routes
  cluster into one feature.
- **No `external` entities because "those are obvious."** They aren't, to
  the next engineer or session. Capture them.
- **`util` as an entity.** No. Decompose it.
- **Listing every type in the codebase as an abstraction.** A type with one
  implementer is not an abstraction; it is a struct.
