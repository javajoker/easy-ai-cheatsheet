---
name: squad-dispatch
description: Invoke a squad member under control — per its MEMBER.md invocation contract, inside a worktree sandbox, with an explicit input allowlist, a cost cap, a timeout, and full transcript capture to docs/squad/dispatches/<date>-<slug>.md, closing with a ledger line in docs/squad/ledger.md. The only path through which external members are ever called: real tasks, eval golden tasks, and onboarding smoke tests all go through here, so reliability/latency/cost data accumulates in one place. Use this skill when a routing decision exists and names a member ("dispatch it", "send it to gemini-cli", squad-lead step 3, eval-run phase 1, member-onboard's smoke test). Refuses to dispatch without a routing decision (or smoke-test/eval context), refuses inputs beyond the allowlist, and never streams secrets — auth comes from the environment per the contract, never from the prompt. Pairs with squad-route (upstream decision), squad-verify (downstream gate — dispatch never integrates anything itself), and the member sheets (the contracts it executes).
---

# Squad Dispatch

The controlled doorway. Members are outside processes with their own
billing, failure modes, and data paths — so every call gets the same
treatment: sandboxed, capped, logged, and **never integrated by this
skill** (that's `squad-verify`'s gate).

## Procedure

### Phase 0 — Preconditions

- A routing decision names the member (or this is an `eval-run` golden
  task / `member-onboard` smoke test — those carry their own context).
- The member's `MEMBER.md` invocation contract exists and was
  smoke-tested.
- The **input allowlist** is explicit: exactly the files/content the task
  needs. Re-check its data class against the member's clearance — the
  route checked it, but the allowlist may have grown since.

### Phase 1 — Prepare the sandbox

- File-editing dispatches run in a **dedicated worktree** (never the
  user's working tree), holding only allowlisted content where the
  contract permits.
- Prompt-only members (e.g. `ollama run`) get allowlisted content inlined
  into the prompt — nothing else.
- Build the command from the contract verbatim. Auth comes from the
  environment as the contract names it; **no secret ever appears in a
  prompt, an argument, or the transcript.**

### Phase 2 — Set the caps

- **Timeout:** the contract's default unless the task justifies more
  (note why).
- **Cost cap:** from the routing decision's estimate. Metered members
  whose runs blow past the estimate get stopped, not topped up — a wrong
  estimate is a finding for the ledger, not a reason to spend more.
- **Retries:** zero, at this layer. Invocation *errors* (auth, network)
  may be retried once after diagnosis; a *bad output* is never retried
  here — that's the verify-driven ladder, which feeds back gaps.

### Phase 3 — Invoke and capture

Run it. Capture into `docs/squad/dispatches/<date>-<slug>.md`:

- The routing decision (head of the record).
- Verbatim command (auth redacted), start/end time, exit status.
- Output: stdout inline (or referenced if huge); file changes as a diff
  against the sandbox baseline.
- Cost actually metered (or band estimate when not meterable) + latency.
- The return's self-reported `confidence`, if the kit's output schema
  carries the field — recorded as a **signal for `squad-verify`**, never
  acted on here (dispatch integrates nothing).

Hangs hit the timeout and are recorded as failures; partial output is
kept in the record (it may still inform the retry's gap notes).

### Phase 4 — Hand off and ledger

- Hand the record to [`squad-verify`](../squad-verify/). **This skill
  never merges sandbox changes** — outputs stay quarantined until
  verify's PASS.
- Append the ledger line to `docs/squad/ledger.md`:
  `| date | task class | member | estimated | actual (all-in: member + orchestration tax + verify) | baseline (in-house est.) | <verify outcome — filled by squad-verify> | escalations |`.
  A reused result writes a `cache-hit` line with zero member cost (see
  `squad-state`'s verified-result cache). The **all-in vs. baseline**
  pair is what makes the ledger a running squad-vs-in-house benchmark,
  not just a spend log.

## Anti-patterns

- **Dispatching from the user's working tree.** A member that edits
  files operates on a sandbox, full stop.
- **Allowlist drift.** "It might also need the config" — every addition
  re-checks data class. Convenience is how secrets leak.
- **Topping up a blown cap.** Stop, record, re-route or escalate.
- **Quiet redispatch.** A failed call that's silently retried with a
  tweaked prompt corrupts the reliability record that evals and ratings
  stand on. Every invocation lands in the record.
- **Bypassing the doorway.** A bare `gemini -p` in Bash skips the
  sandbox, the caps, and the ledger — the three things that make
  delegation safe. All member calls come through here.

## Companion skills

| When… | Use |
|---|---|
| The upstream decision | `squad-route` |
| Judging what came back | `squad-verify` |
| The contract being executed | `members/<name>/MEMBER.md` |
| Long dispatch sessions near /compact | `compact-ritual` |
