# Gate Vocabulary — concrete examples per metric type

Gates must be **measurable**, **specific**, and **tied to a dashboard**.
"Looks fine" is not a gate.

## Error-rate gates

```
canary_error_rate / baseline_error_rate ≤ 1.05 over 1h window
```

Dashboard: `<url>` — panel "canary vs baseline error rate".

Variants:

- Per status class: `5xx_rate ≤ 1.1× baseline` (let 4xx have more tolerance).
- Per endpoint: gate by critical endpoints, not aggregate.
- Per error type: structured errors classified; new error types fail
  the gate even if aggregate count looks fine.

## Latency gates

```
canary_p99_latency ≤ baseline_p99 × 1.10 over 30 min
canary_p95_latency ≤ baseline_p95 × 1.10 over 30 min
canary_p50_latency ≤ baseline_p50 × 1.20 over 30 min
```

p99 is the hardest gate — small regressions show up in the tail
first.

## SLO burn-rate gates

Tied to SLOs from `devops-observability`:

```
slo_burn_rate < 6×  (slow-burn threshold)
slo_burn_rate < 14.4× (fast-burn threshold; auto-abort)
```

Multi-window: gates check both the short window (5 min) and the
longer window (1h) to catch both spikes and sustained drift.

## Resource-saturation gates

USE-style:

```
cpu_utilization < 70% sustained
memory_utilization < 80% sustained
db_connection_pool_saturation < 80%
queue_depth < threshold_per_service
```

The canary version may legitimately use *more* resources (new
features cost something). Threshold is set based on infrastructure
headroom, not "no change vs. baseline".

## Business-metric gates

Tied to product metrics from `gtm-analytics-instrumentation`:

```
signup_completion_rate ≥ baseline × 0.95
activation_rate ≥ baseline × 0.95
payment_success_rate ≥ baseline × 0.98
conversion_rate ≥ baseline × 0.95
```

These are the gates that catch when the change works
*technically* but breaks the user experience or business outcome.

## Dependency-health gates

Downstream services:

```
downstream_<service>_error_rate < 1% over 10 min
downstream_<service>_latency_p95 < threshold
```

Important: changes that pass internal gates can still cause
downstream cascades. Always include downstream gates for changes
to high-traffic services.

## Gate combinations

Each stage transition typically has **5–8 gates**, not just one.
Per-stage gate table from the `rollout-strategy-template.md`:

```markdown
| Gate | Source | Threshold |
|---|---|---|
| Error rate | <dashboard url> | ≤ 1.05× baseline |
| Latency p99 | <dashboard url> | ≤ 1.10× baseline |
| SLO burn-rate slow | <dashboard url> | < 6× |
| CPU saturation | <dashboard url> | < 70% |
| Business: signup rate | <dashboard url> | ≥ 95% of baseline |
| Downstream: payment service errors | <dashboard url> | < 1% |
```

## Bad gates

| Bad gate | Why bad | Better |
|---|---|---|
| "Canary looks healthy" | Opinion, not measurable | One of the gates above |
| "Error rate seems normal" | "Seems" is not a threshold | `≤ 1.05× baseline over 1h` |
| "No customer complaints" | Lag indicator; customers don't always complain | Telemetry-based gate |
| "Engineer checked dashboard" | Not reproducible; not automatic | Automated check against threshold |
| "Gates green at one point in time" | Doesn't account for soak | Sustained over window |

## Gate authoring discipline

1. **Tie to a dashboard URL** — copy-paste in the gate definition.
2. **Threshold is a number with a unit** — "5%" not "low".
3. **Sustained over a window** — never "at point-in-time".
4. **Comparable to baseline** — not absolute thresholds (baselines
   shift over time).
5. **Automatable** — humans can override, but the default should be
   automatic.
