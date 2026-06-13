---
name: squad-state
description: The shared status/memory mechanism across squad members, models, and modalities — a per-job State Ledger (docs/squad/jobs/<job-id>/ledger.json) that members mutate through hydrated payloads and verified deltas instead of conversational history, eliminating token compounding in multi-member jobs. Owns the ledger schema (entries with producer provenance, verification status, and modality), the hydration rule (a dispatch carries only the state keys its node declares), the merge rule (deltas stay quarantined until squad-verify passes — the Glass Box: quarantined state is human-readable and editable before merge), the cross-modal rule (every artifact entry pairs the artifact with a text summary so text-only members can consume it), and the end-of-job distillation into memory-ontology for cross-session durability. Use this skill when a job spans more than one dispatch ("share the extraction with the coder", "what does the ledger say", "merge the delta", "resume the job from last good state"), when squad-plan creates a multi-node job, or when the user asks how members share memory. Pairs with squad-plan (nodes declare required_inputs/outputs as ledger keys), squad-dispatch (hydrates payloads from the ledger), squad-verify (gates every merge), kit-build (kits' output deltas are ledger-shaped), and memory-ontology (cross-session distillation).
---

# Squad State

Members never talk to each other. They are pure functions —
`member(kit, hydrated payload) → delta` — and the **State Ledger** is
the only shared memory: one JSON file per job that every node reads
from (narrowly) and writes to (through verification). This is how
status and memory cross models and modalities without dragging an
ever-growing chat history through every call — the token-compounding
failure the reference docs name as the central problem.

## The ledger

`docs/squad/jobs/<job-id>/ledger.json`, with artifacts beside it under
`docs/squad/jobs/<job-id>/artifacts/`:

```json
{
  "job": {
    "id": "2026-06-13-benchmark-charts",
    "objective": "one sentence — the only context every node shares",
    "budget": { "cap": "<band/amount>", "spent_so_far": "<running>" }
  },
  "entries": {
    "extracted_metrics": {
      "value": { "q1_revenue": 45000000 },
      "producer": "gemini-cli@node-01",
      "at": "2026-06-13T10:37:00Z",
      "status": "verified",
      "modality": "data"
    },
    "trend_chart": {
      "artifact": "artifacts/trends.png",
      "summary": "line chart, Q1–Q4 revenue, two series; Q3 dip visible",
      "producer": "codex-cli@node-03",
      "at": "2026-06-13T10:52:10Z",
      "status": "quarantined",
      "modality": "image"
    }
  }
}
```

Every entry carries **provenance** (who produced it, at which node),
**status** (`quarantined` → `verified`; only verified entries hydrate
into later nodes), and **modality**.

## The four rules

### 1. Hydration — read narrowly

A dispatch payload carries *only* the ledger keys its node declared as
`required_inputs` (plus the one-line job objective). Never the whole
ledger, never upstream transcripts, never "for context." This is the
token saving: node 4 fixing a script sees the script and the error log
— not the 50 pages node 1 extracted them from.

### 2. Delta merge — write through the gate

Members return deltas matching their kit's output schema. A delta lands
`quarantined` and **stays out of every later hydration** until
`squad-verify` passes it (then `verified`) or rejects it (recorded,
never merged; the escalation ladder runs). This is the reference docs'
quarantine/backtrack mechanic: a failed node never poisons the ledger,
and the job resumes from the last verified state. The quarantine is
also the **Glass Box**: the user can read — and with a note, edit — a
quarantined delta before deciding; state is controlled, not behavior
hoped-for.

### 3. Cross-modal — artifact + summary, always

Non-text outputs (images, audio, binaries, large files) live in
`artifacts/` and enter the ledger as `artifact` + **mandatory text
`summary`**. Hydration then serves each member what it can consume per
its sheet's `modalities`: a vision-capable member gets the artifact, a
text-only member gets the summary — same entry, no separate bookkeeping.
A summary that wouldn't let a text-only member act on the entry is too
thin; rewrite it.

### 4. Distill — the ledger is working memory, not long-term memory

At job end, durable facts (a routing pattern that worked, a member
quirk, a reusable plan) distill into `memory-ontology` /
`docs/squad/playbook/`; the ledger itself stays with the job as the
audit record. Nothing reads a closed job's ledger as live state.

## Procedure (conducting state for a job)

1. **Open** — create the ledger at job start (`squad-plan` does this
   for planned jobs; single-dispatch tasks don't need one).
2. **Hydrate** — per node, assemble the payload from the node's
   `required_inputs` ∩ verified entries. A required key that is missing
   or quarantined blocks the node — surface it, don't improvise.
3. **Merge** — on verify PASS, move the delta's keys in with
   provenance; on FAIL, record the rejection in the entry's history and
   leave the last verified value standing.
4. **Resume** — a job interrupted (session end, circuit breaker, human
   pause) resumes by re-reading the ledger: verified entries are the
   checkpoint; in-flight nodes re-dispatch.
5. **Close** — final verify of the job deliverable, budget line
   reconciled to the main ledger (`docs/squad/ledger.md`), distillation
   note written.

## Anti-patterns

- **Chat-style handoffs.** "Here's what the extractor said…" pasted
  into the next prompt is the compounding history this mechanism
  exists to kill. Keys in, deltas out.
- **Hydrating the whole ledger.** "It's small now" — it won't be, and
  narrow hydration is also the context-isolation guarantee.
- **Merging quarantined deltas** because the next node is blocked.
  Blocked is the correct state; verify or escalate.
- **Secrets in the ledger.** Same rule as dispatch: the ledger is a
  project artifact read by many parties; auth and secrets never enter
  it.
- **Summary-free artifacts.** An artifact only vision members can
  consume splits the squad's shared memory by modality — the summary
  is what keeps it shared.

## Companion skills

| When… | Use |
|---|---|
| Declaring nodes' required_inputs/outputs | `squad-plan` |
| Building payloads from the ledger | `squad-dispatch` (hydration executor) |
| Gating every merge | `squad-verify` |
| Shaping member output as deltas | `kit-build` (output schema) |
| Cross-session durability of distilled facts | `memory-ontology` |
