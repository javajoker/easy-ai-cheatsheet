---
name: devops-observability
description: Establishes the technical observability baseline for a service — structured JSON logs with correlation IDs, RED metrics per service + USE metrics per resource, distributed traces via OpenTelemetry with per-env sampling, one golden-signals dashboard per service, one SLO per critical user journey, and burn-rate alerts that fire before the budget is spent. Output is logging-config, metrics-config, tracing-config, dashboard specs, and alert rules ready to deploy against the chosen backend (Loki+Prometheus+Tempo+Grafana / Datadog / Honeycomb / Lightstep / Grafana Cloud). Distinct from gtm-analytics-instrumentation (which owns product telemetry — signup, activation, retention). Use this skill when the user asks "add observability", "we need metrics", "set up logging", "what are our SLOs", "build the dashboards", "set up alerts". Pairs with devops-ci-cd (post-deploy smoke + silence alerts during deploys), with devops-incident-runbook (runbooks point at these dashboards), with devops-iac (telemetry backend provisioned via IaC), with arch-rollout-strategy (rollout gates depend on these metrics), and with gtm-analytics-instrumentation (technical + product telemetry coexist; this skill owns the technical side).
status: shipped
owner_agent: devops-engineer
---

# DevOps Observability

The technical telemetry baseline. Defaults to **OpenTelemetry**
because OTel lets the backend stay swappable — start with cheap
self-host, migrate to SaaS without re-instrumenting.

> **Distinct from product telemetry.** `gtm-analytics-instrumentation`
> owns *product* telemetry — signup, activation, retention,
> feature adoption. This skill owns *technical* telemetry —
> latency, errors, saturation, traces. Both have dashboards; both
> have alerts. They pair; they don't overlap.

## Why this exists

Observability failures are predictable:

1. **Logs in stdout, nowhere to query.** "Where's the request
   that failed?" → grep + tail + tears.
2. **Metrics by accident.** A counter here, a histogram there;
   no consistent shape; no aggregation possible.
3. **Tracing as a someday-project.** When the incident hits and
   the cause is in another service, traces don't exist.
4. **Alert spam.** Every metric alerts on every change; on-call
   stops reading; the one real alert is missed.
5. **No SLOs.** "Is the service healthy?" → opinion, not data.

This skill ships an opinionated baseline so observability is set
up the same way across projects, with SLOs that make health
testable, with alerts that fire before users notice.

## When to fire

Fire when:

- The user asks *"add observability"*, *"set up logging"*, *"we
  need metrics"*, *"build the dashboards"*, *"set up alerts"*,
  *"define our SLOs"*.
- A project is preparing for prod (any project; observability is
  part of the prod gate).
- An incident exposes a visibility gap — extend the baseline to
  cover it.

Do **not** fire when:

- The project has full observability the team is happy with —
  offer to *audit* via `requirement-audit`.
- The user wants product telemetry — that's `gtm-analytics-
  instrumentation`.
- The "observability" request is really a single dashboard tweak
  — do the tweak; don't impose the baseline.

## Inputs

Required:

- `INSTRUCTIONS/projects/<slug>/project-context.md` — stack +
  hosting target.
- (Optional) `TECH_DESIGN.md` — declares critical paths +
  performance targets that become SLOs.

Asked once (cap at 3):

1. **Backend choice.**
   - **Self-host** (default for new projects): Loki + Prometheus
     + Tempo + Grafana.
   - **SaaS**: Datadog / New Relic / Honeycomb / Lightstep /
     Grafana Cloud / Axiom.
2. **Trace sampling preference.** All envs 100% (high-cost / low-
   volume) vs. tiered (dev 100%, staging 50%, prod 10%, with
   error-biased sampling on top).
3. **SLO target.** Default 99.9% per critical journey (≈8.6h
   downtime / year). Specify otherwise per journey.

## The three pillars + the gate

### Pillar 1 — Logs

**Format:** structured JSON. Always.

**Required fields (every log line):**

- `timestamp` (ISO 8601 with timezone).
- `level` (`debug` / `info` / `warn` / `error` / `fatal`).
- `service` (which service emitted).
- `correlation_id` (or `trace_id`) — propagates across services.
- `message` (human-readable).
- `attrs` (structured key-value pairs; never stringify what
  could be structured).

**Sampling:**

- `debug` only in dev / staging.
- `info` everywhere; can be sampled in prod if volume forces
  it (rare).
- `warn` / `error` / `fatal` — always 100%.

**What never goes in logs:**

- PII (emails, names, SSNs, credit cards).
- Auth tokens (access tokens, refresh tokens, API keys, session
  cookies).
- Request bodies for sensitive endpoints (auth, payments,
  personal data).

If a log line *might* contain sensitive data, redact at emit
time, not at query time.

### Pillar 2 — Metrics

Two complementary models:

**RED** (per service — measures the service):

- **R**ate — requests per second.
- **E**rrors — error rate (per status class, per error type).
- **D**uration — latency distribution (p50, p95, p99 minimum).

**USE** (per resource — measures the host / container /
database):

- **U**tilization — % busy.
- **S**aturation — queued / pending work.
- **E**rrors — resource-level errors.

Both go up via OpenTelemetry instrumentation. The frameworks
(`devops-ci-cd`-built containers) auto-emit much of this; custom
business metrics are added at the application layer.

**Metric naming convention:**

- snake_case, `<namespace>.<subsystem>.<metric>_<unit>`.
- Example: `http.server.duration_ms`, `db.query.duration_ms`,
  `signup.attempt_count`.

### Pillar 3 — Traces

**Sampling:**

| Env | Default sample rate | Always-traced |
|---|---|---|
| Dev | 100% | – |
| Staging | 100% | – |
| Prod | 10% | errors (100%); high-latency (100%); tail-based on request bias |

**Span shape:**

- Every external call traced (HTTP, DB, queue, cache).
- Every cross-service boundary propagates `trace_id`.
- Custom spans for known-expensive operations (LLM call, file
  upload, complex query).

**Trace context propagation:** W3C TraceContext header
(`traceparent`) is the default. Don't invent custom headers.

### The gate — SLOs

For each critical user journey (typically 3–6 per service),
define an SLO:

| Field | Example |
|---|---|
| Journey name | "Signup completion" |
| Indicator (SLI) | % of signup attempts that complete within 5s |
| Target (SLO) | 99.9% over rolling 30 days |
| Error budget | 0.1% = ~43m of allowable misses / month |
| Burn-rate alert (fast) | budget consumed at 14.4× → page on-call |
| Burn-rate alert (slow) | budget consumed at 6× over 6h → notify channel |

The burn-rate alerts fire **before** the budget is spent — this
is the discipline that prevents *"we found out from twitter"*
incidents.

## The procedure

### Phase 1 — Pick the backend

Per the inputs question. Stack picks:

| Choice | Components |
|---|---|
| Self-host | Loki (logs) + Prometheus (metrics) + Tempo (traces) + Grafana (dashboards) |
| Datadog | Single SaaS for all three pillars |
| New Relic | Single SaaS for all three pillars |
| Honeycomb | Excellent for traces; pair with Prometheus + Loki for metrics + logs |
| Grafana Cloud | Hosted version of the self-host stack |

OTel emits to all of these; only the collector configuration
differs.

### Phase 2 — Wire OTel into the app

For each language:

- **Node**: `@opentelemetry/sdk-node` + auto-instrumentations.
- **Python**: `opentelemetry-distro` + `opentelemetry-bootstrap`.
- **Go**: `go.opentelemetry.io/otel` + per-library instrumentation.
- **Java**: OpenTelemetry Java agent (jar attached at runtime).

The skill generates the per-language bootstrap code + the
collector config. Defaults: emit to localhost OTel Collector;
collector forwards to the chosen backend.

### Phase 3 — Build the dashboards

One **golden-signals dashboard per service**, with rows:

- Request rate (RED-R).
- Error rate by class (RED-E).
- Latency distribution: p50 / p95 / p99 over time (RED-D).
- Saturation: in-flight requests, queue depth.
- Resource: CPU + memory + disk over time.
- Dependency health: per downstream service / DB / cache.

Plus an **SLO dashboard** showing burn-rate per SLO with the
fast + slow alert thresholds drawn as horizontal lines.

Generate dashboards as code (JSON / YAML) so they live in the
repo and migrate with the project.

### Phase 4 — Alerts

| Alert class | Source | Threshold | Routes to |
|---|---|---|---|
| Service down | Health check failing | 2 consecutive failures | Page on-call |
| Error rate spike | RED-E | >2× baseline for 5 min | Page on-call |
| Latency regression | RED-D p95 | >2× baseline for 10 min | Page on-call |
| SLO fast burn | Burn rate >14.4× | 5 min | Page on-call |
| SLO slow burn | Burn rate >6× | 6h | Notify channel |
| Resource saturation | USE-S | >80% for 30 min | Notify channel |
| Dependency degraded | Downstream error rate | >1% for 10 min | Notify channel |

Each alert has:

- **Runbook link** (pointing at `devops-incident-runbook` output).
- **First-responder** named.
- **Auto-silence** during planned deploys (CI/CD pipeline
  silences relevant alerts for ~10 min around deploy).

### Phase 5 — Document the SLOs

Write `slos.md` in the project (or `docs/observability/slos.md`):

- One section per critical journey.
- Per-SLO: SLI definition, target, budget, alert thresholds,
  dashboard URL, runbook URL.
- Quarterly review cadence — SLOs drift from reality if not
  re-checked.

### Phase 6 — Validate

- Logs land in the chosen backend; sample query returns recent
  lines.
- Metrics show up in Prometheus / chosen tool; sample dashboard
  renders.
- Traces visible end-to-end across at least one cross-service
  call.
- A test alert fires (synthetic failure) and routes correctly.

## Anti-patterns

- **Unstructured logs.** Stringified JSON or plain text in 2026
  is technical debt. Structure or move on.
- **PII in logs / traces.** Easy to slip in, expensive to remove
  retroactively. Redact at emit time.
- **No correlation IDs.** Cross-service debugging becomes
  archaeology. Propagate them.
- **Alert on every metric change.** Alert fatigue → real alerts
  missed. Alert on what *requires action*.
- **SLO without budget.** A target without a budget is a wish.
  Budgets give the team permission to spend reliability for
  velocity (or vice versa).
- **Vendor lock-in via direct SDK.** Direct vendor SDKs make
  backend swaps expensive. OTel is the abstraction.
- **Dashboards as snowflakes.** Hand-built per-service dashboards
  with no shared shape → reading a new service feels foreign.
  Use a template.

## Companion skills

- `devops-ci-cd` — post-deploy smoke + silence alerts during
  deploys.
- `devops-incident-runbook` — runbooks point at these dashboards.
- `devops-iac` — backend hosting.
- `arch-rollout-strategy` — rollout gates use these metrics.
- `gtm-analytics-instrumentation` — product telemetry counterpart.
- `requirement-audit` — verify SLOs are being maintained at
  review time.

## Reference files

- [references/otel-collector-baseline.yaml](references/otel-collector-baseline.yaml) —
  starter OTel Collector config.
- `references/golden-signals-dashboard.json` — Grafana dashboard
  spec (importable).
- `references/slo-worksheet.md` — guided worksheet for defining
  per-journey SLOs.
- `references/alert-rules-baseline.yaml` — Prometheus AlertManager
  rules for the baseline alert classes.
