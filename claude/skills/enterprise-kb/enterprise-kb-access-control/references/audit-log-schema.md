# Audit Log Schema

Schema for the KB access audit log. Designed for ingestion into
the observability stack (`devops-observability`).

## Record shape

Every retrieval / read against a canonical entity emits one
record:

```json
{
  "timestamp": "2026-05-15T14:23:45.123Z",
  "event_type": "kb_access",
  "principal": {
    "id": "alice@example.com",
    "type": "human",
    "classification": "internal",
    "roles": ["eng-platform", "eng-all"]
  },
  "entity": {
    "id": "auth-service",
    "domain": "products",
    "type": "shipped",
    "classification": "internal"
  },
  "query": "auth service architecture",
  "query_hash": "<sha256 if redaction applied>",
  "outcome": "success",
  "redaction_applied": false,
  "source": {
    "ip": "10.0.4.23",
    "pod": "kb-retrieval-7d4f5b-x9k2",
    "user_agent": "kb-retrieval-python/1.2.3"
  },
  "correlation_id": "trace-abc123def456",
  "retrieval_ms": 47,
  "result_count": 8
}
```

## Field reference

### Top-level

| Field | Type | Required | Description |
|---|---|---|---|
| `timestamp` | ISO 8601 UTC | yes | When the access occurred |
| `event_type` | enum | yes | `kb_access` (current); future: `kb_admin`, `kb_modification` |
| `principal` | object | yes | Who accessed |
| `entity` | object | yes | What was accessed |
| `query` | string | optional | Original query (may be hashed if sensitive) |
| `query_hash` | string | optional | SHA-256 of query if `query` redacted |
| `outcome` | enum | yes | `success` / `denied` / `refused` / `error` |
| `redaction_applied` | bool | yes | Whether result was redacted |
| `source` | object | yes | Where the request originated |
| `correlation_id` | string | yes | Trace ID for cross-system correlation |
| `retrieval_ms` | int | yes | Server-side processing time |
| `result_count` | int | yes | Number of results returned (post-ACL filter) |

### `principal`

| Field | Type | Description |
|---|---|---|
| `id` | string | Stable identifier (email for humans; service name for services; agent session id for agents) |
| `type` | enum | `human` / `service` / `agent` / `ci_run` |
| `classification` | enum | Caller's max access level (`public` / `internal` / `restricted` / `confidential` / `regulated`) |
| `roles` | string[] | Roles the principal belongs to (used for restricted-access checks) |

### `entity`

| Field | Type | Description |
|---|---|---|
| `id` | string | Canonical entity ID |
| `domain` | string | Top-level domain |
| `type` | string | Sub-type |
| `classification` | enum | Entity's classification at access time |

### `outcome` values

| Value | Meaning |
|---|---|
| `success` | Entity returned to caller (possibly with redaction; see `redaction_applied`) |
| `denied` | Caller authenticated but lacked permission (e.g. principal is `internal`, entity is `restricted`) |
| `refused` | Caller's request was structurally invalid (malformed token, unauthenticated) |
| `error` | Server error (caller may retry); not security-relevant |

### `source`

| Field | Type | Description |
|---|---|---|
| `ip` | string | IPv4 or IPv6 source address |
| `pod` | string | Kubernetes pod ID or equivalent (for service callers) |
| `user_agent` | string | Client SDK + version |

---

## Storage

| Concern | Default |
|---|---|
| Destination | `<observability backend>` — typically same place as application logs |
| Format | JSON line per record (NDJSON) |
| Ingestion path | OpenTelemetry log exporter → backend |
| Encryption | At rest (provider-default); in transit (TLS) |
| Tenancy | Separate index / log group per `environment` |

---

## Retention per entity classification

| Entity classification | Audit log retention |
|---|---|
| public | 90 days |
| internal | 90 days |
| restricted | 1 year |
| confidential | 2 years |
| regulated (HIPAA) | 7+ years |
| regulated (PCI) | 1+ year |
| regulated (GDPR-sensitive) | per regulation |

Implementation: tag each log record with entity classification;
log backend applies retention per tag.

---

## Indexes for query patterns

Common audit queries (build indexes accordingly):

| Query pattern | Index |
|---|---|
| "Who accessed entity X in the last 30d?" | `entity.id` + `timestamp` |
| "What did principal Y access?" | `principal.id` + `timestamp` |
| "How many denials in the last 24h?" | `outcome` + `timestamp` |
| "Anomalies for confidential entities" | `entity.classification` + `principal.id` |

---

## Anomaly detection queries

### Off-hours human access to restricted+

```sql
SELECT *
FROM kb_audit_log
WHERE entity_classification IN ('restricted', 'confidential', 'regulated')
  AND principal_type = 'human'
  AND EXTRACT(HOUR FROM timestamp) NOT BETWEEN 9 AND 17  -- local TZ
  AND timestamp > NOW() - INTERVAL '1 hour'
ORDER BY timestamp DESC;
```

### Principal frequency anomaly

```sql
WITH baseline AS (
  SELECT principal_id, COUNT(*)::float / 30 AS daily_avg
  FROM kb_audit_log
  WHERE timestamp BETWEEN NOW() - INTERVAL '30 days' AND NOW() - INTERVAL '1 day'
  GROUP BY principal_id
),
today AS (
  SELECT principal_id, COUNT(*) AS today_count
  FROM kb_audit_log
  WHERE timestamp > NOW() - INTERVAL '1 day'
  GROUP BY principal_id
)
SELECT t.principal_id, t.today_count, b.daily_avg,
       t.today_count / b.daily_avg AS ratio
FROM today t
JOIN baseline b USING (principal_id)
WHERE t.today_count > b.daily_avg * 10  -- 10x spike
ORDER BY ratio DESC;
```

### Repeated denials (potential probing)

```sql
SELECT principal_id, COUNT(*) AS denial_count
FROM kb_audit_log
WHERE outcome = 'denied'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY principal_id
HAVING COUNT(*) >= 5
ORDER BY denial_count DESC;
```

---

## Privacy considerations

- **Query content** may contain PII (e.g. "customer named Alice
  Smith"). Hash via SHA-256 if log destination isn't itself
  classified for handling such content.
- **Source IP** is PII under GDPR; treat audit logs as
  restricted access.
- **Audit log access** is itself audit-logged (recursive but
  bounded — one extra entry per audit query).

---

## Anti-patterns

- **No timestamp granularity.** Second-level precision is
  insufficient for forensic analysis. Use milliseconds.
- **Logging full result content.** Audit log records *that*
  access happened, not *what* was returned. Don't log result
  bodies.
- **No correlation_id.** Cross-system tracing impossible. Always
  include.
- **Indexing on entity.id alone.** Most useful queries use
  `entity.id + timestamp` (recent access for an entity); ensure
  composite index.
- **Retention misaligned with entity classification.** Log says
  7-year retention but log records expire at 90 days → audit
  trail incomplete. Match retention to classification.
