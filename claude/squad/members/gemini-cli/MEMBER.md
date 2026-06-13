---
name: gemini-cli
product: Gemini CLI
vendor: Google
interface: cli
status: probation
cost_band: low
data_handling: BLOCKED
evaluated: []
member_version: UNVERIFIED — run `gemini --version` at onboarding and record it
---

# Gemini CLI

Google's open-source terminal AI agent. On the roster for the low cost
band — historically a generous free/low-cost tier — making it the first
candidate for high-volume text task classes (`translation`,
`summarize-extract`, `doc-writing`, `bulk-transform`) and for
`research` (built-in web grounding). Everything below is `(claimed)`
until Scenario W runs.

## Invocation contract

> Verify each line against the installed version at onboarding; CLIs
> change flags between releases. The smoke test is the proof.

- **Command:** `gemini -p "<prompt>"` (non-interactive prompt mode)
- **Auth:** Google account login or API key env var per vendor docs —
  name the mechanism here once confirmed; never store the value
- **Input:** prompt arg and/or stdin; files via the working directory
- **Output:** stdout
- **Non-interactive flags:** `-p` runs one-shot; confirm yolo/approval
  flags before any dispatch that edits files
- **Timeout default:** 600s
- **Smoke test:** `gemini -p "Reply with exactly: squad-ok"`

## Capability sheet

| Capability / limit | Tag | Source |
|---|---|---|
| Very large context window | (claimed) | vendor docs — verify the number for the current model at onboarding |
| Built-in web search grounding | (claimed) | vendor docs — candidate for `research`; eval it |
| Multilingual strength | (claimed) | vendor docs — candidate for `translation`; eval it (see EXAMPLES.md Example 1 for the eval shape) |
| Free-tier rate limits may throttle bulk dispatches | (claimed) | vendor docs — measure during the first bulk eval |

## Cost model

(claimed) Free tier with daily/minute rate limits; paid API keys lift
them. Record your account's actual limits at onboarding. The ledger
supplies `(measured)` lines — for free-tier work, the measurable cost is
latency and retry overhead, not dollars.

## Data handling

**BLOCKED.** Free tiers often have broader data-use terms than paid ones
— read the terms for *your* auth mode specifically, record what was read
and the date, then clear per data class. Until then, `public`-class eval
fixtures only.

## Eval history

| Date | Task class | Scorecard | Outcome |
|---|---|---|---|
