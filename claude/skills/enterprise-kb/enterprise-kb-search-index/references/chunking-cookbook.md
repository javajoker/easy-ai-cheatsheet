# Chunking Cookbook — per entity type

Chunking decisions per entity type. The default: 1 chunk per
entity; long entities get 2–3 chunks at natural section
boundaries.

## Pattern 1 — Single-chunk entity (default)

For most entities (terminology, customers, partners, teams, most
decisions):

```
[entity_id: tenant]
[domain: terminology]
[type: canonical]
[chunk: 1/1 — Definition + Context]
[classification: internal]
[updated: 2026-05-10]
[aliases: Workspace, Account, Organisation]

# Tenant

## Definition

A logically isolated customer workspace; the unit of multi-
tenancy + billing. One tenant maps to one billing account; one
tenant can contain many users.

## Context

The canonical org-wide definition. Not interchangeable with
"user" (a person) or "billing-account" (a finance record),
although the three closely relate.

## Where it appears

- API: `/api/v1/tenants/`
- Database: `tenants` table
- Billing: `billing_accounts.tenant_id`
- All products under `stardust` family
```

Single chunk; whole entity content + prefix; embedded as one
vector.

---

## Pattern 2 — Multi-section entity (2–3 chunks)

For long entities (architectural decisions with rationale,
runbooks with multi-section walkthroughs):

### Chunk 1/3

```
[entity_id: jwt-rotation-decision-2025]
[domain: decisions]
[type: architectural]
[chunk: 1/3 — Definition + Context]
[classification: restricted]
[updated: 2025-08-22]
[aliases: Refresh Token Single-Use]

# JWT Refresh-Token Rotation Policy 2025

## Definition

Refresh tokens are single-use: each refresh request issues a
new refresh token and invalidates the old.

## Context

Adopted after the 2025-Q2 security review surfaced replay risk
on long-lived refresh tokens. Decision driven by SOC2
attestation requirements.
```

### Chunk 2/3

```
[entity_id: jwt-rotation-decision-2025]
[domain: decisions]
[type: architectural]
[chunk: 2/3 — Implementation]
[classification: restricted]
[updated: 2025-08-22]

# JWT Refresh-Token Rotation Policy 2025

## Implementation

The auth-service issues refresh tokens with a one-time-use flag.
On each refresh request:

1. Validate the presented refresh token.
2. Mark it consumed.
3. Issue a new refresh token + access token pair.
4. If the same refresh token is presented twice, all sessions for
   that user are revoked.

The single-use flag is enforced via the auth-service's token
ledger (Postgres `token_state` table).
```

### Chunk 3/3

```
[entity_id: jwt-rotation-decision-2025]
[domain: decisions]
[type: architectural]
[chunk: 3/3 — Rollout + impact]
[classification: restricted]
[updated: 2025-08-22]

# JWT Refresh-Token Rotation Policy 2025

## Rollout

Phased over 4 weeks:
1. Backend: enable issuance of single-use refresh tokens.
2. Mobile + web clients: handle rotation in client SDKs.
3. Mandate single-use on all new sessions.
4. Migrate legacy sessions on next refresh.

## Impact

- Mobile + web clients required SDK upgrades.
- Refresh latency increased 40ms (acceptable per perf review).
- Replay-attack risk eliminated (per Q3 security audit).
```

---

## Pattern 3 — Sub-type-specific patterns

### runbooks/incident

5 sections of the fixed runbook shape. **Always 5 chunks** to
preserve section integrity for retrieval (the retriever may
need only the Diagnose section, not the whole runbook).

- Chunk 1/5 — Detect
- Chunk 2/5 — Diagnose
- Chunk 3/5 — Mitigate
- Chunk 4/5 — Recover
- Chunk 5/5 — Postmortem trigger

### products/shipped

2 chunks typical:

- Chunk 1/2 — Definition + Context + Where it appears (the user-
  facing slice)
- Chunk 2/2 — tier_table + integration details (the operational
  slice)

### terminology/canonical

Always 1 chunk. Terminology entries are short; splitting hurts
retrieval.

### decisions/strategic

1 chunk default; 2–3 if the decision has multi-section rationale
+ implications.

---

## Natural boundary rules

Split at:

- ✅ Markdown `## H2` headings.
- ✅ Markdown `### H3` headings (for very long sections).
- ✅ Numbered-step boundaries (mid-list split is fine if step is
  complete).
- ✅ Code-block boundaries (don't split inside a code block).

Never split at:

- ❌ Mid-sentence.
- ❌ Mid-list-item.
- ❌ Mid-table.
- ❌ Mid-code-block.

---

## Chunk size targets

| Target | Range | Notes |
|---|---|---|
| Soft minimum | 200 tokens | Below this, dense vector lacks discriminating signal |
| Sweet spot | 400–700 tokens | Strong vector + sparse signal |
| Soft maximum | 1000 tokens | Above this, retrieval LLM loses focus |
| Hard maximum | 1500 tokens | Above this, embedding model's effective context wanes |

For short entities (terminology, customers) that don't fit the
soft minimum, **still use one chunk** — pad with prefix; the
search will still work, the vector just won't be especially
informative beyond exact-match signals.

---

## Chunk prefix discipline

The prefix is **mandatory**. Without it, mid-entity chunks lose
context. The prefix:

- Adds ~50 tokens overhead per chunk.
- Is included in embedding (so semantic queries about
  "architectural decisions" find decision-prefixed chunks).
- Is included in BM25 (so exact-match queries on entity_id find
  the chunk).
- Is included in retrieval result (so the LLM consumer sees the
  context).

---

## Re-chunking triggers

Re-chunk when:

- The entity's content changes substantively.
- The chunking strategy changes (e.g. switch from 2-chunk to
  3-chunk for a domain).
- The embedding model upgrades (re-chunk + re-embed).

Re-chunk = re-embed = re-index. Plan ahead — full re-embed is
the most expensive operation in KB maintenance.

---

## Anti-patterns

- **No prefix.** Chunks lose context; retrieval works but the
  consumer LLM lacks discriminating info.
- **Fixed-size chunking.** Splitting every 500 tokens regardless
  of structure breaks tables, code blocks, and lists.
- **Per-paragraph chunking.** Over-chunks; each chunk has too
  little signal.
- **Chunk-spanning context.** Forcing one logical concept across
  two chunks. The concept fragments at retrieval.
- **Including frontmatter in body chunks.** Frontmatter is metadata,
  goes in the prefix; not the chunk content.
