# members — per-product capability sheets

One folder per squad member, one `MEMBER.md` per folder. These are the
squad layer's **workers** — the same role `maintenance/versions/tune-for-*`
sheets play for version tuning: provenance-tagged facts that the
dispatching skills load at runtime. `member-onboard` scaffolds them;
`eval-run` adds `(measured)` evidence; `member-retune` flags staleness.

## Provenance tags

Every capability or limit line carries exactly one tag:

- **`(claimed)`** — from vendor docs, release notes, or public benchmarks.
  Decides what to evaluate first; never moves a rating. Always cite the
  source.
- **`(measured)`** — from an eval run you executed; cites the scorecard
  under `docs/squad/evals/`.
- **`(stale)`** — was `(measured)`, but the product version moved
  underneath it (`member-retune` sets this). Treated as one rating lower
  until re-measured.

Never write an untagged factual line, and never upgrade `(claimed)` to
`(measured)` without a scorecard to cite.

## The MEMBER.md template

```markdown
---
name: <kebab-case-member-name>
product: <official product name>
vendor: <vendor>
interface: cli | api | mcp
status: probation            # mirrors ROSTER.md; roster wins on conflict
cost_band: free | low | mid | premium
data_handling: BLOCKED       # BLOCKED | cleared: public | cleared: internal | cleared: sensitive
evaluated: []                # ["<task-class>@<member-version>", ...] — set by eval-run
member_version: <model/CLI version the evidence below is anchored on>
---

# <Member name>

One paragraph: what this product is and why it's on the roster.

## Invocation contract

How `squad-dispatch` calls it. Must be runnable non-interactively from Bash.

- **Command:** `<exact command shape, with prompt/file placeholders>`
- **Auth:** `<env var or login mechanism — name it, never store it here>`
- **Input:** how files/context are passed (args, stdin, flags)
- **Output:** where the result lands (stdout, files) and how to capture it
- **Non-interactive flags:** what prevents it waiting for input
- **Timeout default:** <seconds>
- **Smoke test:** the one-liner `member-onboard` ran, verbatim

## Capability sheet

| Capability / limit | Tag | Source |
|---|---|---|
| <context window, modes, languages, tool use, etc.> | (claimed) | <vendor doc / release note> |
| <eval results land here> | (measured) | docs/squad/evals/<class>/<member>-<date>.md |

## Cost model

(claimed) lines from vendor pricing + (measured) lines from the ledger.
State the unit (per token / per request / subscription / free-local).

## Data handling

Starts **BLOCKED**. A human clears it per data class after reading the
vendor's data-use terms — note here what was read and when. `squad-route`
refuses to send a data class this section doesn't clear.

## Eval history

| Date | Task class | Scorecard | Outcome |
|---|---|---|---|
```

## Disciplines

- **The sheet is not an ad.** Limits and failure modes are as load-bearing
  as capabilities — the trap-task results especially.
- **`member_version` anchors everything.** When it changes, run
  `member-retune`, don't hand-edit tags.
- **Secrets never land here.** Auth lines name the env var; values live in
  your secret store.
