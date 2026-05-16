# Observability Baseline (agent-level pointer)

The canonical baseline lives in the `devops-observability` skill:
[`skills/devops/devops-observability/SKILL.md`](../../../skills/devops/devops-observability/SKILL.md).

The reference templates for that skill:

- [`otel-collector-baseline.yaml`](../../../skills/devops/devops-observability/references/otel-collector-baseline.yaml) — starter OTel Collector config.
- [`slo-worksheet.md`](../../../skills/devops/devops-observability/references/slo-worksheet.md) — per-journey SLO worksheet.
- [`golden-signals-dashboard.json`](../../../skills/devops/devops-observability/references/golden-signals-dashboard.json) — Grafana spec.
- [`alert-rules-baseline.yaml`](../../../skills/devops/devops-observability/references/alert-rules-baseline.yaml) — Prometheus rules.

## What the agent guarantees

When `devops-engineer` declares the observability workstream done,
every service in scope has:

1. **Structured JSON logs** with correlation IDs, landing in the
   chosen backend.
2. **RED metrics per service** (rate / errors / duration) emitted
   via OpenTelemetry.
3. **USE metrics per resource** (utilization / saturation / errors)
   from infra-side collectors.
4. **Traces** propagated via W3C TraceContext across every external
   call.
5. **One golden-signals dashboard per service**.
6. **One SLO per critical user journey** with multi-window
   multi-burn-rate alerts.
7. **Alerts wired** to the named channels with runbook links.

The skill enforces this — the agent just confirms.
