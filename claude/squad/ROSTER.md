# ROSTER — who can do what, today

The single source of routing truth. `squad-route` reads this file at
runtime; `eval-run`, rating feedback, and `member-retune` update it —
always through a diff preview (Gate 4), never silently. If a rating here
has no `(measured)` evidence on the member's sheet, the rating is wrong:
fix the roster, not the sheet.

## Status vocabulary

- **home** — the product this framework runs on (Claude Code). Conductor,
  verifier, and executor of last resort; not routed *to*, it routes.
- **active** — may take work per its ratings.
- **probation** — newly onboarded or under review; `throwaway` stakes only.
- **benched** — kept on the roster, takes no work (ledger didn't justify
  the seat, or terms under review).
- **retired** — sheet archived; row kept for ledger history.

## Rating vocabulary (per member × task class)

- **A — trusted.** Clears `ship` stakes; verify-light (spot checks).
- **B — capable.** Clears `internal` stakes; full verify. B is the floor
  for anything that lands in the repo.
- **C — probationary quality.** `throwaway` stakes only; double-verify if
  its output is ever kept.
- **U — unrated.** No `(measured)` evidence. Takes nothing that matters.
- A `(stale)` suffix (set by `member-retune`) means the evidence predates
  a version change: routing treats it as one rating lower until
  re-measured.

## Stakes bar

| Task stakes | Minimum rating | Verify depth |
|---|---|---|
| `throwaway` (drafts, evidence-generation) | C | spot check |
| `internal` (docs, tooling, non-shipped) | B | full |
| `ship` (lands in shipped code/docs) | A (B allowed with explicit user OK) | full |

## Cost bands

`free` (local), `low`, `mid`, `premium`. Bands order routing among
eligible members; exact pricing lives on each member's sheet and the
truth lives in the ledger.

## Budget threshold (Gate 2 auto-proceed)

Dispatches with estimated cost in `free`/`low` band auto-proceed after
the routing decision is surfaced; `mid` and above, sensitive data, or
`ship` stakes always ask first. Adjust this line per project if needed.

## The matrix

Task classes: `bulk-transform` · `code-gen` · `code-review` · `test-gen`
· `doc-writing` · `translation` · `summarize-extract` · `research`.

| Member | Status | Band | bulk-transform | code-gen | code-review | test-gen | doc-writing | translation | summarize-extract | research |
|---|---|---|---|---|---|---|---|---|---|---|
| [`claude-code`](members/claude-code/MEMBER.md) | home | premium | — | — | — | — | — | — | — | — |
| [`codex-cli`](members/codex-cli/MEMBER.md) | probation | mid | U | U | U | U | U | U | U | U |
| [`gemini-cli`](members/gemini-cli/MEMBER.md) | probation | low | U | U | U | U | U | U | U | U |
| [`ollama-local`](members/ollama-local/MEMBER.md) | probation | free | U | U | U | U | U | U | U | U |

The home row carries no ratings — in-house is always eligible and is the
fallback of every route. All other members ship **U everywhere** by
design: this file records *your* measurements, not anyone's reputation.
Run Scenario W (see [SCENARIOS.md](SCENARIOS.md)) on the task classes you
actually want to route.

## The kit matrix (fine-grained — preferred by routing when present)

The class matrix above is coarse: "can this member translate?" The kit
matrix is the precise question the layer is built for: "can this member
execute *this packaged skill*, our way, to PASS?" A kit rating is
anchored on an eval against the kit's own acceptance criteria (Scenario
W with a kit), so it predicts production behaviour far better than the
class cell. **`squad-route` prefers a kit rating over the class rating
whenever the task maps to a kit.**

| Member | Kit | Rating | Evidence | Notes |
|---|---|---|---|---|
| *(none yet — build kits with `kit-build` for the skills you route most, then eval; see* [`kits/README.md`](kits/README.md) *and EXAMPLES.md Example 1/4)* | | | | |

A kit rating cell carries the same A/B/C/U vocabulary and `(stale)`
suffix as the class matrix. When `kit-build` re-derives a kit and its
contract or criteria change, ratings against the old kit go `(stale)`
until re-measured (`member-retune` discipline).

## Update discipline

- Rating moves cite a scorecard (`docs/squad/evals/...`) or a ledger
  record — in the diff's commit/proposal text, every move names its
  evidence.
- Demotion: two verified failures at the rating's stakes level in the
  rolling record → proposal. Promotion: a fresh eval or a sustained pass
  record → proposal. Never a single anecdote in either direction.
- Status moves to `benched`/`retired` cite the ledger summary
  (`member-retune` produces it).
