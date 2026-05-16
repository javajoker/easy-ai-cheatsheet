# Architecture Assessment — <slug>

**Version:** 1
**Locked:** YYYY-MM-DD
**Assessor:** <name>
**Decision authority:** <name>
**Status:** active | draft | superseded
**Scope:** <whole system | specific service | specific concern>

---

## Context

**Triggering concern.** <one paragraph — what prompted this assessment>

**Time available for assessment.** <e.g. 1 week>

**Related documents.**

- Project knowledge base: <link if exists>
- Recent postmortems referenced: <list>
- Observability dashboards consulted: <list>

---

## 1. Current-state diagram

```mermaid
graph TB
  User[User] --> LB[Load Balancer] (confirmed)
  LB --> API[API Service<br/>Node.js / Fastify] (confirmed)
  API --> DB[(Postgres 15<br/>RDS)] (confirmed)
  API --> Cache[(Redis)] (confirmed)
  API --> Queue[Background Queue<br/>BullMQ] (inferred — config not in repo)
  Queue --> Worker[Worker Service] (inferred)
  Worker --> External[Stripe API] (confirmed)
```

**Legend.**

- Solid: confirmed via code / config / docs.
- Dashed: inferred — pending walkthrough confirmation.

**Open inferred items** (need walkthrough):

- Queue + Worker subsystem — no IaC; assumed from `bull` dep + scripts.
- <…>

---

## 2. Hot paths

### Path 1 — <name, e.g. "Signup → first session">

| Field | Value |
|---|---|
| Traversed components | User → LB → API → DB → Email worker |
| SLA target | p95 < 3s end-to-end |
| Current performance | p95 = 2.4s (per Datadog 30d avg) (confirmed) |
| Failure mode if degrades | New users abandon at confirmation step; activation funnel breaks |

### Path 2 — <name>

(same shape)

---

## 3. Pain points

| # | Symptom | Anchor | Affected component(s) | Cost of doing nothing |
|---|---|---|---|---|
| P1 | Database CPU >80% during EU business hours | <Grafana link>; incident 2026-03-12 (confirmed) | Postgres primary | 2× weekly p95 spike; risk of scaling event |
| P2 | Deploy of API service requires worker restart | Devops retro 2026-04 (confirmed) | API + worker coupling | 30 min/week deploy overhead; locks Friday deploys |
| P3 | Single team owns auth + billing + core | Org chart (confirmed) | All services | Bus-factor-1; release coordination cost |

---

## 4. Risk register

| # | Risk | Severity | Likelihood | Detect signal | Mitigation if it materialises |
|---|---|---|---|---|---|
| R1 | DB write throughput hits ceiling | high | med (12 mo) | Write IOPS sustained >80% | Vertical scale (90d runway) → sharding (high cost) |
| R2 | Single Postgres failure → multi-hour outage | high | low | Primary unavailability | Failover to standby (15 min); incident postmortem |
| R3 | Compliance regime change (GDPR scope expansion) | med | med | Regulatory news | Multi-region deployment work — currently single-region |
| R4 | Team attrition on auth subsystem | high | med | Voluntary departure flag | Bus-factor mitigation: pair-up + docs sprint |

---

## 5. Options matrix

### Option 0 — Status quo (do nothing)

| Field | Value |
|---|---|
| Description | Keep current architecture; address pain points tactically (DB tuning, deploy automation). |
| Addresses pain points | P1 (partially via tuning); P2 (with effort); P3 (no) |
| Time-to-migrate | 0 (ongoing maintenance) |
| Reversibility | n/a |
| Team capability fit | high |
| Operational cost change | 0% short-term; +20% in 12 months as scaling pressure increases |
| Risk profile | R1 materialises within 12 months without intervention. |
| Critical assumption | "Growth stays within 1.5× over 12 months" |

### Option A — Extract auth service (vertical split)

| Field | Value |
|---|---|
| Description | Move auth code + auth tables to a dedicated service + DB. Other services consume via auth API. |
| Addresses pain points | P2 (decouple deploys), P3 (auth team owns auth) |
| Time-to-migrate | 8–12 weeks |
| Reversibility | medium (need to re-merge if it doesn't work) |
| Team capability fit | high (auth team exists) |
| Operational cost change | +15% (new service infra + ops) |
| Risk profile | Auth API failure = total outage. Mitigated by caching + circuit breakers. |
| Critical assumption | "Auth API can hit p99 < 50ms reliably" |

### Option B — Adopt event-driven core (horizontal restructure)

| Field | Value |
|---|---|
| Description | Move from sync RPC to event bus (Kafka or similar). Services subscribe to relevant events. |
| Addresses pain points | P1 (decouples DB write paths), P2 (deploy independence) |
| Time-to-migrate | 6–12 months |
| Reversibility | low (significant rewrite) |
| Team capability fit | low (no streaming experience) |
| Operational cost change | +40% (Kafka cluster + ops + new tooling) |
| Risk profile | High — team learning curve; event-loss bugs are subtle. |
| Critical assumption | "Async semantics fit our consistency requirements" — needs verification per business flow |

### Option C — Vertical scaling + tactical tuning

| Field | Value |
|---|---|
| Description | Bigger DB instance + read replicas + query optimisation. No architectural change. |
| Addresses pain points | P1 (yes — direct relief) |
| Time-to-migrate | 2–4 weeks |
| Reversibility | high |
| Team capability fit | high |
| Operational cost change | +25% (bigger DB instance) |
| Risk profile | Defers the architectural decision 9–18 months; pain returns. |
| Critical assumption | "Vertical headroom buys enough time for a better solution" |

---

## 6. Recommendation

**Recommended option:** Option C → then Option A within 6 months

**Rationale.** Option C buys runway (low cost, fast, reversible)
while we build organisational capability for Option A. Option B
is premature — team capability fit is too low and reversibility
is too low to justify in the current context.

**Why not the higher-scored alternative.** Option B addresses
more pain in one move but the risk of a low-capability team
attempting it within 12 months outweighs the benefit.

---

## 7. Decision record

**Decided on:** YYYY-MM-DD (pending — to be filled when authority decides)
**Decided by:** <decision authority>
**Decision:** <option>
**Rationale:** <if differs from recommendation>

---

## 8. Open inferred items (post-walkthrough)

Items still tagged `(inferred)` after the user walkthrough:

| Item | Why still inferred | Plan to confirm |
|---|---|---|
| Queue throughput limits | No load test data | Schedule load test in next sprint |
| <…> | | |

---

## Change log

| Version | Date | Change | By |
|---|---|---|---|
| 1 | YYYY-MM-DD | initial assessment | <name> |
| 1 | YYYY-MM-DD | inferred walkthrough complete | <name> |
| 1 | YYYY-MM-DD | decision recorded | <name> |
