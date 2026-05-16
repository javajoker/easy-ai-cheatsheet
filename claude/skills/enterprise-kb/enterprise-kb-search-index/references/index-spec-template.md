# Enterprise KB Search Index Spec

**Version:** 1
**Locked:** YYYY-MM-DD
**Owner:** <name>
**Status:** active | draft | superseded

---

## Vector DB

**Choice:** pgvector | Pinecone | Weaviate | Qdrant | Milvus | Chroma | other

**Rationale.** <one paragraph: scale fit, ops familiarity, cost,
existing stack alignment>

**Hosting.** <self-host via `devops-iac` | managed cluster URL |
SaaS account>

**Estimated scale.**

- Entity count: <N>
- Chunks per entity: 1–3 typical
- Total chunks: <total>
- Embedding dimension: <e.g. 1536>
- Storage estimate: <e.g. ~50 MB at 1M chunks × 1536d × float32>

---

## Embedding model

**Model:** OpenAI text-embedding-3-small | text-embedding-3-large | Sentence-Transformers/all-MiniLM-L6-v2 | Sentence-Transformers/BGE-large | Voyage-3 | Cohere embed-v3

**Dimension:** <e.g. 1536>

**Rationale.** <one paragraph>

**Version pin.** <model identifier + version> — locked here; do
not silently upgrade. Embedding upgrades require full re-embed.

---

## Reranker

**Choice:** Cohere rerank-3 | cross-encoder/ms-marco-MiniLM-L-6-v2 (self-host) | none (dense-only)

**Rationale.** <one paragraph>

---

## Chunking strategy

**Per-entity chunk count:** 1–3 (most entities = 1; long entities
= 2–3 at natural section boundaries)

**Chunk size target:** <e.g. 500–800 tokens>

**Chunk overlap:** <e.g. none — entities are self-contained>

**Chunk metadata prefix** (every chunk):

```
[entity_id: <id>]
[domain: <domain>]
[type: <sub-type>]
[chunk: <i/n> — <chunk title>]
[classification: <classification>]
[updated: <YYYY-MM-DD>]
[aliases: <comma-separated>]

<chunk content>
```

The prefix ensures:

- Retrieval LLMs see entity context even when only the chunk is
  shown.
- Mid-entity chunks know they're not the whole entity.
- Classification is available for downstream ACL enforcement.

---

## Retrieval

### Hybrid (dense + BM25)

| Component | Tool | Notes |
|---|---|---|
| Dense (vector) | Vector DB above | Cosine similarity |
| Sparse (BM25) | <e.g. Postgres FTS / OpenSearch / Weaviate hybrid native> | Token match |
| Merge | Reciprocal Rank Fusion (RRF, k=60) | Standard |
| Rerank | <reranker above> | Top-N → top-K |

### Defaults

| Parameter | Default | Notes |
|---|---|---|
| Top-N (pre-rerank) | 50 | Tune per recall needs |
| Top-K (post-rerank) | 10 | Tune per LLM context budget |
| Sparse weight | 0.3 (in RRF k tweak) | Adjust per query types |

### Filter parameters

Per-query filters (passed to retrieval client):

- `domain`: restrict to specific top-level domains.
- `type`: restrict to specific sub-types.
- `classification_max`: cap on classification (e.g. `internal`
  means restricted+ entities excluded).
- `status`: `active` (default) or include sunset entities.
- `updated_after`: only entities updated since date.

---

## ACL enforcement

ACLs enforced **at retrieval**, not at the LLM layer. The
retrieval client takes a `principal` parameter and filters
results per the principal's access (see
`enterprise-kb-access-control`).

```python
class KBRetrievalClient:
    def search(
        self,
        query: str,
        *,
        top_k: int = 10,
        filters: dict | None = None,
        principal: Principal,            # mandatory
    ) -> list[RetrievalResult]:
        ...
```

Below-classification results are **omitted** from the returned
list (not redacted — fully absent).

---

## Refresh wiring

Re-index triggers:

- After every `enterprise-kb-merge` run — incremental re-index
  of changed entities.
- After every sunset action — remove from default search.
- On scheduled refresh from `enterprise-kb-refresh-policy`.
- Manual full re-index on embedding model or chunking change.

Incremental re-index: only embed + index entities whose
`updated:` changed since last index timestamp.

---

## Retrieval API

Client SDK in:

- Python: `kb_retrieval` package on internal PyPI.
- Node/TS: `@org/kb-retrieval` on internal npm.
- Go: `github.com/<org>/kb-retrieval-go`.

API contract:

```
POST /api/v1/kb/search
Authorization: Bearer <principal-token>
{
  "query": "string",
  "top_k": 10,
  "filters": { "domain": ["products"] }
}

→ {
  "results": [
    {
      "entity_id": "<id>",
      "chunk_idx": 0,
      "score": 0.93,
      "text": "<chunk text with prefix>",
      "metadata": { ... entity frontmatter (excluding sensitive) ... }
    },
    ...
  ],
  "total_found": <count>,
  "retrieval_ms": <int>
}
```

---

## Eval benchmark

A small benchmark of `(query, expected_entity_ids)` pairs run
weekly to monitor retrieval quality drift:

See [`eval-benchmark-template.md`](eval-benchmark-template.md).

Metrics tracked:

- Recall@10 — fraction of expected entities in top-10.
- MRR — mean reciprocal rank of expected entities.
- P50 / P95 retrieval latency.

---

## Operational

| Concern | Approach |
|---|---|
| Hosting | `devops-iac` provisions vector DB |
| CI/CD | Re-index triggered by merge workflow |
| Monitoring | `devops-observability` dashboard: index size, retrieval latency, error rate, eval scores |
| Backup | Snapshots per vector DB's pattern; embeddings reproducible from canonical entities |
| Disaster recovery | Full re-embed from canonical (cost: ~$X per embedding call × N chunks) |

---

## Change log

| Version | Date | Change | By |
|---|---|---|---|
| 1 | YYYY-MM-DD | initial spec | <name> |
