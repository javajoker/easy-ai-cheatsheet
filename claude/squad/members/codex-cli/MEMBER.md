---
name: codex-cli
product: Codex CLI
vendor: OpenAI
interface: cli
status: probation
cost_band: mid
data_handling: BLOCKED
roles: [generator]                # rate it as a verifier before using it as a check=<name>
evaluated: []
member_version: UNVERIFIED — run `codex --version` at onboarding and record it
---

# Codex CLI

OpenAI's terminal coding agent. On the roster as the most direct
like-for-like alternative for coding task classes (`code-gen`,
`test-gen`, `code-review`, `bulk-transform`). Everything below is
`(claimed)` until Scenario W runs — this sheet was scaffolded, not
measured.

## Invocation contract

> Verify each line against the installed version at onboarding; CLIs
> change flags between releases. The smoke test is the proof.

- **Command:** `codex exec "<prompt>"` (non-interactive exec mode)
- **Auth:** OpenAI account login / API key per vendor docs — name the
  mechanism here once confirmed; never store the value
- **Input:** prompt arg; repo files via the working directory
- **Output:** stdout + file edits in the working directory (sandboxed
  worktree when dispatched)
- **Non-interactive flags:** `exec` mode; confirm approval-mode flags so
  it never blocks on a prompt
- **Timeout default:** 600s
- **Smoke test:** `codex exec "Reply with exactly: squad-ok"`

## Capability sheet

| Capability / limit | Tag | Source |
|---|---|---|
| Agentic coding in the terminal: reads/edits files, runs commands | (claimed) | vendor docs — verify at onboarding |
| Strong on mainstream-language code generation | (claimed) | public reputation — this is exactly what `(claimed)` means; eval it |
| Starts cold per dispatch — no access to this session's context | (claimed) | structural; true of every external member |

## Cost model

(claimed) Subscription and/or API-metered depending on account type —
record which applies to *your* account at onboarding, and the band it
implies. The ledger supplies `(measured)` cost-per-task lines.

## Data handling

**BLOCKED.** Before clearing any data class, read the vendor's current
data-use/retention terms for your account tier and record here what was
read and the date. Until then, `squad-route` will not send it repo
content beyond `public`-class eval fixtures.

## Eval history

| Date | Task class | Scorecard | Outcome |
|---|---|---|---|
