---
name: enterprise-kb-search-index
description: Builds an embedding + retrieval search index over the enterprise KB for RAG and agent grounding — chunking strategy (per entity, 1–3 chunks each prefixed with entity id + type + chunk title so retrieval preserves context), embedding model choice, vector DB choice (pgvector / Pinecone / Weaviate / Qdrant / Milvus), hybrid retrieval (dense + BM25) with reranking, refresh wiring (re-index on entity update), and a documented retrieval API contract so all consuming AI features share one client. Output is enterprise-kb/search-index/ with the index config + ingestion code + retrieval client + API contract docs. Use this skill when the user says "set up RAG over the KB", "build the search index", "we need retrieval", "AI features need to query the KB"; or when enterprise-kb-merge has populated the canonical layer and AI features depend on querying it. Pairs with enterprise-kb-architecture (entity structure drives chunking), with enterprise-kb-merge (re-index after every merge), with enterprise-kb-refresh-policy (refresh triggers re-index), with enterprise-kb-access-control (retrieval enforces ACLs), with devops-engineer agent (hosting the index + ingestion pipeline), and with lifecycle-pilot agent (AI features consuming the index).
status: shipped
owner_agent: knowledge-curator
---

# Enterprise KB Search Index

Phase 4 of the `knowledge-curator` agent. Makes the KB
retrievable. Eliminates the common failure where each AI
feature rolls its own RAG index against the same source-of-
truth.

> **One shared index, many consumers.** Each AI feature
> querying the KB uses the same retrieval client. If a feature
> needs something the shared index doesn't provide, that's a
> signal the shared index has a gap — fix the gap; don't fork.

## Why this exists

RAG-over-KB failures are predictable:

1. **Per-feature index.** Each AI feature builds its own
   index; same source data; different chunking / embedding /
   retrieval; results disagree across features.
2. **Chunk-context loss.** Naive chunking splits an entity
   across chunks; retrieval returns mid-sentence fragments
   without context.
3. **Dense-only retrieval.** Pure vector search misses exact-
   match queries ("show me the Stripe runbook"); user
   frustration.
4. **No reranking.** Top-k retrieval surfaces noise alongside
   signal; downstream LLM gets distracted.
5. **Stale index.** Index built once; KB updates; index drifts;
   features return outdated information without warning.
6. **No ACL enforcement.** Index serves restricted entities to
   any caller; security breach via retrieval API.

This skill ships an opinionated index with shared client,
context-preserving chunking, hybrid retrieval + reranking,
refresh wiring, and ACL enforcement at the retrieval layer.

## When to fire

Fire when:

- An AI feature is being built that needs to query the
  enterprise KB.
- The user says *"set up RAG over the KB"*, *"build the
  search index"*, *"we need retrieval"*, *"AI features need
  to query the KB"*.
- `enterprise-kb-merge` has populated a canonical layer and
  the user wants it queryable.

Do **not** fire when:

- The KB has no canonical layer yet (run `enterprise-kb-
  merge` first).
- A single AI feature wants its own specialised index — push
  back; the shared index is the architectural choice unless
  there's a specific reason (e.g. radically different chunk
  granularity).
- The use case is full-text search only (no embeddings); use
  a simpler search system.

## Inputs

Required:

- Populated `enterprise-kb/entities/`.
- `enterprise-kb/ARCHITECTURE.md` (entity contract — used for
  chunk metadata).
- `enterprise-kb/access-control.md` if it exists (else default
  to internal — restrictive).

Asked once (cap at 3):

1. **Vector DB.** pgvector (default if Postgres already in
   stack) / Pinecone / Weaviate / Qdrant / Milvus / Chroma /
   custom.
2. **Embedding model.** OpenAI text-embedding-3-small
   (default) / text-embedding-3-large / Sentence-Transformers
   (self-host) / Voyage / Cohere.
3. **Reranker.** Cohere rerank-3 (default if reranking budget
   available) / cross-encoder self-host / none (dense-only
   retrieval).

## The opinionated index design

### Chunking strategy

**Per entity, 1–3 chunks.** Why so few:

- Most entities (decisions, terminology, products) fit in one
  chunk.
- Long entities (architectural decisions with deep rationale;
  runbooks with multi-section walkthroughs) split at
  natural boundaries (headings).
- Never split mid-sentence; never split mid-list.

**Every chunk is prefixed with metadata:**

```
[entity_id: auth-service]
[domain: products]
[type: shipped]
[chunk: 1/2 — Definition + Context]
[classification: internal]
[updated: 2026-05-10]

<actual chunk content>
```

This prefix ensures:

- Retrieval LLMs see what entity the chunk is from, even if
  only the chunk content is shown.
- Mid-entity chunks know they're not the whole entity.
- Classification is available for downstream ACL enforcement.

### Embedding model choice

Defaults driven by use case:

| Use case | Recommended model |
|---|---|
| General-purpose RAG (default) | OpenAI text-embedding-3-small (cost-efficient; 1536d) |
| High-quality / nuanced retrieval | OpenAI text-embedding-3-large or Voyage-3 (3072d) |
| Self-host / offline / cost-sensitive at scale | Sentence-Transformers all-MiniLM-L6-v2 or BGE-large |
| Code-heavy KB | OpenAI text-embedding-3-large or specialised code-embedding model |
| Multilingual | OpenAI / Voyage / multilingual-e5 |

Document the choice + rationale. **Don't mix models** within a
single index (similarity becomes meaningless).

### Vector DB choice

| Vector DB | Use when |
|---|---|
| **pgvector** (default for stacks already on Postgres) | Postgres in stack; <10M chunks; team familiar |
| **Pinecone** | Hosted SaaS; large scale; team doesn't want to operate |
| **Weaviate** | Self-host or cloud; rich filtering; hybrid native |
| **Qdrant** | Self-host friendly; high-performance; good metadata filtering |
| **Milvus** | Very large scale (>100M chunks); willing to operate cluster |
| **Chroma** | Prototyping; small scale; simple SDK |

### Hybrid retrieval (dense + BM25)

**Dense (vector) search** finds semantically similar content.

**BM25 (sparse) search** finds exact term matches.

Both run; results merged via reciprocal rank fusion (RRF) by
default. This catches both *"how does auth work"* (semantic)
and *"show me the AUTH-007 decision"* (exact ID match).

### Reranking

After hybrid retrieval surfaces top-N (typically N=20–50), a
reranker re-orders to surface the most-relevant top-K
(typically K=5–10).

| Reranker | Use when |
|---|---|
| Cohere rerank-3 (default) | Hosted; quality; cost-acceptable |
| Cross-encoder (e.g. ms-marco) self-host | No external dependency; lower quality than Cohere |
| None (skip reranking) | Latency-critical; willing to accept lower precision |

### Retrieval API contract

A single documented client. Shape:

```python
class KBRetrievalClient:
    def search(
        self,
        query: str,
        *,
        top_k: int = 10,
        filters: dict | None = None,    # e.g. {"domain": "runbooks"}
        principal: Principal,           # for ACL enforcement
    ) -> list[RetrievalResult]:
        """
        Hybrid retrieval over the enterprise KB.

        ACL: results filtered by `principal`'s access per
        enterprise-kb-access-control. Restricted entities not
        accessible by `principal` are omitted (not redacted in
        result — fully absent).

        Returns: ranked list of RetrievalResult with entity_id,
        chunk text, metadata, score.
        """
```

**Every AI feature uses this client.** No direct vector DB
calls; no per-feature embedding logic; no per-feature ACL
implementation.

### Refresh wiring

Re-index triggers:

- After every `enterprise-kb-merge` run (incremental — only
  changed entities).
- After every sunset action (remove sunset entities from
  default search; remain queryable with explicit flag).
- On `enterprise-kb-refresh-policy` scheduled audit.
- Manual full re-index on embedding model change or chunking
  strategy change.

Incremental re-index avoids full rebuilds; the index stays
near-live with the KB.

## The procedure

### Phase 1 — Read architecture + canonical state

Open `ARCHITECTURE.md`. Pull entity contract (used for chunk
metadata).

Open `enterprise-kb/entities/`. Count entities per domain;
estimate total chunk count (most entities = 1 chunk; some =
2–3).

This estimate drives vector DB choice (pgvector fine <10M;
larger may need dedicated vector DB).

### Phase 2 — Pick vector DB + embedding + reranker

Per inputs + the recommendations above. Document the rationale.

### Phase 3 — Implement the chunker

For each entity:

- Read frontmatter (extract metadata for chunk prefix).
- Apply chunking rules (natural boundaries; max 1–3 chunks).
- Generate chunk text with prefix.
- Emit chunk records: `(entity_id, chunk_idx, text, metadata)`.

### Phase 4 — Generate embeddings

Embed every chunk via the chosen model. Store embeddings
alongside chunk metadata in the vector DB.

### Phase 5 — Implement BM25 indexing

Parallel index for BM25 (often the vector DB supports this
natively — pgvector + Postgres FTS; Weaviate hybrid; Qdrant
sparse). Otherwise add a separate BM25 store (OpenSearch /
Elasticsearch).

### Phase 6 — Implement hybrid retrieval

Per query:

1. Run dense retrieval — top-N by vector similarity.
2. Run BM25 retrieval — top-N by term match.
3. Merge via reciprocal rank fusion.
4. Optionally rerank top-N → top-K.
5. Apply ACL filter (per `enterprise-kb-access-control`).
6. Return ranked results.

### Phase 7 — Implement the retrieval client

Build the `KBRetrievalClient` SDK (per project language).
Publish as an internal package. Document the API contract.

### Phase 8 — Wire ingestion + refresh

Hand off to `devops-engineer`:

- Vector DB hosting (per IaC — `devops-iac`).
- Ingestion pipeline (per CI/CD — `devops-ci-cd`).
- Index monitoring (per `devops-observability` — index
  freshness, retrieval latency, error rate).

### Phase 9 — Document + hand-off

Write `enterprise-kb/search-index/README.md`:

- Chunking strategy.
- Embedding model + version pin.
- Vector DB endpoint + admin contacts.
- Retrieval client usage examples.
- Refresh cadence reference (points at `refresh-policy.md`).
- ACL enforcement reference (points at `access-control.md`).

Persist as `type: project` memory (`kb_search_index_v1`).

### Phase 10 — Watch for index-quality triggers

The index is high-quality when:

- Retrieval latency p99 < target (typically 200ms).
- Result relevance high (per offline eval against a
  benchmark query set).
- ACL violations zero (per audit).
- Stale-result rate low (per consumer feedback).

When any signal degrades, audit: chunking? embedding model?
reranker? refresh cadence?

## Anti-patterns

- **Per-feature index.** Defeats the shared-knowledge purpose
  of the enterprise KB.
- **Naive chunking.** Splitting mid-sentence; not preserving
  entity context.
- **Dense-only retrieval.** Misses exact-match queries.
- **No reranking with high top-N.** Top-50 from dense
  retrieval is noisy; surface the K most-relevant via
  reranker.
- **No refresh wiring.** Index ages silently; consumers serve
  outdated info.
- **ACL at the LLM layer, not retrieval.** Restricted content
  reaches the LLM; the LLM is asked to "not mention it";
  unreliable. Filter at retrieval.
- **Mixing embedding models.** Similarity scores become
  meaningless.
- **No API contract.** Each feature implements its own
  retrieval flow; inconsistency across features.

## Companion skills

- `enterprise-kb-architecture` — entity contract drives chunk
  metadata.
- `enterprise-kb-merge` — re-index trigger.
- `enterprise-kb-refresh-policy` — refresh cadence.
- `enterprise-kb-access-control` — retrieval enforces ACLs.
- `devops-iac` — vector DB hosting.
- `devops-ci-cd` — ingestion pipeline.
- `devops-observability` — index metrics.
- `lifecycle-pilot` (agent) — AI features consuming the index.

## Reference files

- [references/index-spec-template.md](references/index-spec-template.md) —
  canonical search-index spec document.
- `references/chunking-cookbook.md` — chunking patterns per
  entity type.
- `references/retrieval-client-examples/` — sample client
  implementations per language.
- `references/eval-benchmark-template.md` — offline eval
  benchmark for measuring retrieval quality.
