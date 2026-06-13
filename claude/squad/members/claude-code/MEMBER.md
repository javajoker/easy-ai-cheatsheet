---
name: claude-code
product: Claude Code
vendor: Anthropic
interface: cli
status: home
cost_band: premium
data_handling: "cleared: sensitive"   # it's the home product — already trusted with the repo
roles: [generator, verifier]           # the default verifier + executor of last resort
evaluated: []                          # home is the baseline; it is not eval-rated
member_version: current session model (see environment)
---

# Claude Code (home)

The product this framework runs on. It is the **conductor** (runs
`squad-lead`, routing, and verification), the **baseline** every eval is
implicitly compared against, and the **executor of last resort** — the
bottom rung of every escalation ladder. It carries no roster ratings
because in-house is always eligible; the squad exists to decide when *not*
to use this member.

## Invocation contract

In-session work needs no invocation. For dispatching to a *fresh* Claude
Code context (occasionally useful as a clean-room executor):

- **Command:** `claude -p "<prompt>"` (non-interactive print mode)
- **Auth:** existing Claude Code login on this machine
- **Input:** prompt arg; files via the working directory
- **Output:** stdout
- **Non-interactive flags:** `-p` is non-interactive by design
- **Timeout default:** 600s
- **Smoke test:** `claude -p "Reply with exactly: squad-ok"`

## Capability sheet

| Capability / limit | Tag | Source |
|---|---|---|
| Full harness toolset (file edit, Bash, subagents, worktrees, skills) | (claimed) | this session's own environment |
| Premium cost band — the reason this layer exists | (claimed) | account plan |

## Cost model

Premium band; billed through the user's Anthropic plan. The squad's goal
is to reserve this spend for classify/route/verify and for tasks no other
member clears.

## Data handling

Cleared for everything the repo already contains — it is the home product.

## Eval history

Not applicable — home is the baseline, not an eval target.
