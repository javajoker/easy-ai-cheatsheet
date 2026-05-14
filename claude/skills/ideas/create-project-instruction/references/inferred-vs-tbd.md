# Inferred vs TBD — when to fill, when to leave blank

A field in the generated INSTRUCTIONS file is one of three states:

| State | When | How it appears |
|---|---|---|
| **Confirmed** | Explicitly stated in a source | Plain value |
| **Inferred** | Strong indirect signal | Plain value with ` ← inferred` suffix |
| **TBD** | No reliable source | `{TBD — <one-line description>}` |

The rule of thumb: if your evidence wouldn't survive a fact-check, mark it.

## Examples — confirmed

Each row has a clear, direct source.

| Field | Evidence | Output |
|---|---|---|
| Language | `go.mod` says `go 1.22` | `Go 1.22+` |
| Web framework | `import "github.com/gin-gonic/gin"` in main.go | `Gin` |
| Database | TECH_DESIGN.md states "PostgreSQL 15" | `PostgreSQL 15` |
| Build command | `Makefile` has `build:` target with explicit command | `make build` |
| Primary language for code | User said in conversation "we write everything in Go" | `Go` |

## Examples — inferred

Each row has indirect evidence that is *probably* right.

| Field | Evidence | Output |
|---|---|---|
| Lifecycle stage | Latest tag is v2.4.1, commit cadence is steady | `maintenance ← inferred` |
| i18n locales | `locales/` has `en.json` and `zh-TW.json` | `en, zh-TW ← inferred` |
| Deploy target | `Dockerfile` exists, no Kubernetes manifests, no `serverless.yml` | `Docker (single container) ← inferred` |
| Test runner | `*_test.go` files use `t.Run` and `testing.Short()` | `go test ← inferred` |

The `← inferred` suffix is a flag for the user, not a confession. They can
scan the file and confirm or correct in one pass.

## Examples — TBD

Each row is a field with no reliable evidence.

| Field | State | Output |
|---|---|---|
| Stakeholders | No README mention, no CODEOWNERS file | `{TBD — ask the user who owns this project}` |
| Lifecycle stage | New repo, no tags, no commits older than this week | `{TBD — confirm whether this is prototype, MVP, or production}` |
| Primary language for user-facing copy | Code is English, README is Chinese | `{TBD — code uses English, but README is Chinese; clarify intent}` |

The TBD description matters. `{TBD}` alone leaves the next reader guessing
why; `{TBD — <reason>}` lets them resolve it quickly.

## When to push from TBD to inferred

A common temptation: avoid TBDs by making weak inferences. Resist this for
fields whose accuracy matters operationally:

- **Verification commands** — wrong command means wasted Claude runs. TBD,
  ask the user.
- **Primary language** — affects every subsequent artifact. TBD, ask.
- **Deploy target** — affects DevOps tasks. TBD, ask.

Fields where a weak inference is fine because the user will see it
immediately:

- Lifecycle stage.
- "Last updated" estimates.
- Description-level fields that are easy to skim and correct.

## When to push from inferred to confirmed

Only when you have direct evidence. A README that mentions "PostgreSQL"
casually is *not* direct evidence — PostgreSQL might be mentioned because
the project considered it but chose MySQL. Direct evidence:

- A connection string template.
- A migration tool config (`migrations/postgresql.sql`).
- A docker-compose service.
- An explicit "Stack: PostgreSQL" line in a tech design.

## Marker discipline

Be consistent:

- `← inferred` on one line that has a value.
- `{TBD — reason}` for fields with no value.
- Do *not* mix: `<value> ← inferred {TBD}` is confusing.

## Reporting

The Phase 4 report includes the counts:

```
High-confidence facts: 18
Inferred facts to confirm: 5
TBD fields: 3
```

A healthy ratio for Mode A (existing codebase): 70%+ confirmed, 20%
inferred, 10% TBD. If you're at 30% confirmed, you didn't read enough; if
you're at 0% TBD, you're hiding uncertainty.

Mode B (fresh project): TBD will dominate. That is correct.

Mode C (PRD + tech design): confirmed should dominate. If inferred is high,
the source docs are vague — flag that as a finding.
