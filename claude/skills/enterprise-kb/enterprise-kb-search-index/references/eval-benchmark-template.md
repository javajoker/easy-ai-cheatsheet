# Search Index Eval Benchmark

A small benchmark of `(query, expected_entity_ids)` pairs run on
a schedule to detect retrieval quality drift.

## Benchmark file shape

`eval/benchmark-v1.yaml`:

```yaml
version: 1
description: |
  Eval queries representative of real KB usage patterns.
  Updated quarterly; queries added based on actual user search
  logs.

queries:
  # Exact-name queries
  - id: q-001
    query: "auth service"
    expected_top_3:
      - auth-service
    expected_top_10:
      - auth-service
      - auth-service-down
    rationale: "Exact-name lookup; should land at top."

  # Conceptual queries
  - id: q-002
    query: "how does multi-tenancy work"
    expected_top_3:
      - tenant
      - tenant-isolation-decision
    expected_top_10:
      - tenant
      - tenant-isolation-decision
      - users-data-schema
    rationale: "Conceptual lookup; relevance over exact match."

  # Alias queries
  - id: q-003
    query: "what is a workspace"
    expected_top_3:
      - tenant  # via alias
    rationale: "Alias resolution: 'workspace' → tenant."

  # Decision queries
  - id: q-004
    query: "why do we rotate refresh tokens"
    expected_top_3:
      - jwt-rotation-decision-2025
    rationale: "Decision rationale lookup."

  # Runbook queries
  - id: q-005
    query: "auth service is down what do I do"
    expected_top_3:
      - auth-service-down
    rationale: "Runbook by symptom."

  # Sub-section retrieval
  - id: q-006
    query: "how do I mitigate auth service outage"
    expected_top_5_chunks:
      - "auth-service-down#3"  # Mitigate chunk (3/5)
    rationale: "Section-specific retrieval; runbook chunked by section."

  # Cross-entity reasoning
  - id: q-007
    query: "what's the relationship between users and tenants"
    expected_top_5:
      - tenant
      - user
      - users-data-schema
    rationale: "Multi-entity conceptual query."
```

## Eval metrics

For each run, compute:

| Metric | Definition | Target |
|---|---|---|
| **Recall@3** | Fraction of expected entities found in top-3 | ≥80% on `expected_top_3` queries |
| **Recall@10** | Fraction in top-10 | ≥90% |
| **MRR** | Mean reciprocal rank of first expected entity | ≥0.7 |
| **P50 latency** | Median retrieval latency | <200ms |
| **P95 latency** | 95th percentile | <500ms |

## Eval script outline

```python
#!/usr/bin/env python3
"""Run eval benchmark; emit report."""
import yaml
import statistics
from kb_retrieval import KBRetrievalClient, AdminPrincipal

bench = yaml.safe_load(open("eval/benchmark-v1.yaml"))
client = KBRetrievalClient(endpoint=...)

results = []
for q in bench["queries"]:
    start = time.time()
    response = client.search(
        query=q["query"],
        top_k=10,
        principal=AdminPrincipal(),  # bypass ACL for eval
    )
    latency_ms = (time.time() - start) * 1000

    actual_ids = [r.entity_id for r in response.results]
    expected = q.get("expected_top_3") or q.get("expected_top_10") or []

    # Recall@3
    recall_3 = sum(1 for e in expected if e in actual_ids[:3]) / max(len(expected), 1)
    # Recall@10
    recall_10 = sum(1 for e in expected if e in actual_ids[:10]) / max(len(expected), 1)
    # MRR (first matching position)
    mrr = next(
        (1.0 / (i + 1) for i, eid in enumerate(actual_ids) if eid in expected),
        0.0
    )

    results.append({
        "query_id": q["id"],
        "recall_3": recall_3,
        "recall_10": recall_10,
        "mrr": mrr,
        "latency_ms": latency_ms,
    })

# Aggregate
print({
    "avg_recall_3": statistics.mean(r["recall_3"] for r in results),
    "avg_recall_10": statistics.mean(r["recall_10"] for r in results),
    "avg_mrr": statistics.mean(r["mrr"] for r in results),
    "p50_latency_ms": statistics.median(r["latency_ms"] for r in results),
    "p95_latency_ms": statistics.quantiles([r["latency_ms"] for r in results], n=20)[18],
})
```

## Cadence

| Frequency | What |
|---|---|
| **On every index rebuild** | Smoke run (subset; 5 queries) |
| **Weekly scheduled** | Full benchmark |
| **Quarterly** | Full benchmark + benchmark refresh (add queries from user logs) |
| **On embedding model change** | Full benchmark with diff vs prior model |
| **On chunking strategy change** | Full benchmark with diff |

## Drift detection

Alert when:

- **Recall@10 drops by >5%** vs previous run.
- **MRR drops by >0.1** vs previous run.
- **P95 latency increases by >50%**.

Drift typically indicates:

- Embedding model issue (network, version change).
- Vector DB issue (capacity, replication lag).
- Chunking change without re-index.
- Index corruption.

Investigation steps in
`devops-incident-runbook` (filed runbook class:
`kb-eval-degradation`).

## Benchmark maintenance

The benchmark itself drifts:

- Queries become stale as KB content changes.
- New entity types not represented.
- Edge cases discovered in production not in benchmark.

**Quarterly refresh:**

1. Pull top-100 queries from production search logs.
2. Manually label expected entities.
3. Add representative new queries to benchmark.
4. Retire queries about sunset entities.

A benchmark that doesn't evolve becomes a fossil.

## Reporting

Weekly eval results posted to `#kb-quality` channel:

> :bar_chart: Weekly eval — {date}
>
> Recall@3: {recall_3} (Δ {delta} vs last week)
> Recall@10: {recall_10} (Δ {delta})
> MRR: {mrr} (Δ {delta})
> P95 latency: {p95}ms (Δ {delta})
>
> Status: {green | yellow | red}
> {if degraded: "Investigation: {runbook_link}"}
