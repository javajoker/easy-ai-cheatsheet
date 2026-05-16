# Events JSON Schema

The shape `events.json` produced by `gtm-analytics-instrumentation`.
This is the contract frontend + backend implement; no event fires
that isn't in the spec.

## Schema (JSON Schema 2020-12)

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "Product Telemetry Events Spec",
  "type": "object",
  "required": ["version", "events"],
  "properties": {
    "version": {
      "type": "integer",
      "description": "Spec version; bump on breaking changes"
    },
    "events": {
      "type": "array",
      "items": { "$ref": "#/$defs/event" }
    }
  },
  "$defs": {
    "event": {
      "type": "object",
      "required": ["name", "owner", "rationale", "fires_when", "fires_where"],
      "properties": {
        "name": {
          "type": "string",
          "pattern": "^[a-z][a-z0-9_]*_(completed|started|viewed|clicked|opened|closed|sent|received|created|updated|deleted|attempted|succeeded|failed|reached|exited|enabled|disabled|connected|disconnected|installed|uninstalled|invited|accepted|rejected|shared)$",
          "description": "snake_case verb-noun; past tense; specific subject"
        },
        "owner": {
          "type": "string",
          "description": "Team that owns this event (e.g. growth, product, eng)"
        },
        "rationale": {
          "type": "string",
          "description": "Why this event exists — what question it answers"
        },
        "properties": {
          "type": "array",
          "items": { "$ref": "#/$defs/property" }
        },
        "fires_when": {
          "type": "string",
          "description": "Plain-English precise trigger condition"
        },
        "fires_where": {
          "type": "string",
          "enum": ["frontend", "backend", "worker", "third-party"],
          "description": "Where the event is emitted from"
        },
        "depends_on": {
          "type": "array",
          "items": { "type": "string" },
          "description": "Event names that must fire before this can"
        },
        "funnel": {
          "type": "string",
          "enum": ["acquisition", "activation", "retention", "revenue", "referral", "operations"],
          "description": "Which funnel this event participates in"
        },
        "deprecation": {
          "type": "object",
          "properties": {
            "deprecated_at": { "type": "string", "format": "date" },
            "removal_target": { "type": "string", "format": "date" },
            "replacement": { "type": "string" }
          }
        }
      }
    },
    "property": {
      "type": "object",
      "required": ["key", "type"],
      "properties": {
        "key": {
          "type": "string",
          "pattern": "^[a-z][a-z0-9_]*$"
        },
        "type": {
          "type": "string",
          "enum": ["string", "number", "integer", "boolean", "date", "enum", "object", "array"]
        },
        "values": {
          "type": "array",
          "description": "Allowed values when type=enum",
          "items": {}
        },
        "redact": {
          "type": "boolean",
          "default": false,
          "description": "If true, value is hashed before logging (PII protection)"
        },
        "required": {
          "type": "boolean",
          "default": false
        },
        "description": {
          "type": "string"
        }
      }
    }
  }
}
```

## Example `events.json`

```json
{
  "version": 1,
  "events": [
    {
      "name": "signup_completed",
      "owner": "growth",
      "rationale": "Top of activation funnel; primary acquisition metric",
      "funnel": "acquisition",
      "fires_when": "Account created AND email verified",
      "fires_where": "backend",
      "properties": [
        {
          "key": "method",
          "type": "enum",
          "values": ["email", "google", "github"],
          "required": true
        },
        {
          "key": "referrer",
          "type": "string",
          "redact": true,
          "description": "Source URL or campaign tag"
        },
        {
          "key": "plan_intended",
          "type": "enum",
          "values": ["free", "starter", "pro", "enterprise"]
        }
      ]
    },
    {
      "name": "first_value_reached",
      "owner": "product",
      "rationale": "Activation event; defines a user who got value",
      "funnel": "activation",
      "fires_when": "User completes the activation action (per product, e.g. first dashboard saved)",
      "fires_where": "backend",
      "depends_on": ["signup_completed"],
      "properties": [
        {
          "key": "time_to_value_seconds",
          "type": "integer",
          "required": true
        }
      ]
    },
    {
      "name": "feature_x_used",
      "owner": "product",
      "rationale": "Tracks adoption of feature X",
      "funnel": "retention",
      "fires_when": "User completes the primary X workflow",
      "fires_where": "frontend",
      "properties": [
        {
          "key": "x_variant",
          "type": "enum",
          "values": ["legacy", "new"]
        }
      ]
    },
    {
      "name": "payment_completed",
      "owner": "growth",
      "rationale": "Revenue event",
      "funnel": "revenue",
      "fires_where": "backend",
      "fires_when": "Stripe webhook confirms charge succeeded",
      "properties": [
        {
          "key": "amount_cents",
          "type": "integer",
          "required": true
        },
        {
          "key": "currency",
          "type": "enum",
          "values": ["USD", "EUR", "GBP"],
          "required": true
        },
        {
          "key": "plan",
          "type": "enum",
          "values": ["starter", "pro", "enterprise"],
          "required": true
        }
      ]
    }
  ]
}
```

## Validation

Both frontend and backend validate emitted events against this
spec at build time:

```bash
# In CI
npx ajv-cli validate -s schemas/events-spec.schema.json -d events.json
```

Events not in the spec are rejected at emit time (or logged to a
"spec-violation" channel for triage).

## Versioning

Bump `version` on breaking changes (event removed, property
removed, type changed). Additive changes (new event, new optional
property) don't bump version.

Frontend + backend code annotates which spec version they target:

```typescript
// src/analytics/spec-version.ts
export const SPEC_VERSION = 1;
```

If `SPEC_VERSION` mismatches the spec, build fails. Forces
co-evolution.

## Anti-patterns

- ❌ Events without owners — orphaned when team changes.
- ❌ Events without rationale — accumulate forever, never
  cleaned up.
- ❌ camelCase or PascalCase — break the convention; trip up
  filters.
- ❌ Present-tense verbs (`signup_complete` vs `signup_completed`).
- ❌ PII in property keys (`email_alice_example_com` instead of
  `email_address`).
- ❌ PII in property values without `redact: true`.
- ❌ Spec drift — code emits events not in spec, or spec lists
  events code doesn't emit.
