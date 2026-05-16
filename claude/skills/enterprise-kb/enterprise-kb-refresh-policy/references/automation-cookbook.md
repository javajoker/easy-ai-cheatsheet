# Refresh Automation Cookbook

Implementation patterns for the automatic refresh triggers.

## Pattern 1 — CI on merge to mainline (per source)

For each source KB (per-project), trigger an incremental
enterprise-merge when its mainline updates.

### GitHub Actions example

```yaml
# .github/workflows/kb-merge.yml (in each per-project KB repo)
name: KB Merge Trigger

on:
  push:
    branches: [main]
    paths:
      - 'docs/knowledge-base/**'

jobs:
  trigger-merge:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger enterprise KB merge
        uses: peter-evans/repository-dispatch@v3
        with:
          token: ${{ secrets.KB_DISPATCH_TOKEN }}
          repository: <org>/enterprise-kb
          event-type: source-updated
          client-payload: '{"source": "${{ github.repository }}", "commit": "${{ github.sha }}"}'
```

### Enterprise-KB repo receiver

```yaml
# .github/workflows/incremental-merge.yml (in enterprise-kb repo)
name: Incremental Merge

on:
  repository_dispatch:
    types: [source-updated]

jobs:
  merge:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run incremental merge
        run: |
          scripts/merge.sh \
            --source "${{ github.event.client_payload.source }}" \
            --commit "${{ github.event.client_payload.commit }}" \
            --mode incremental \
            --dry-run-first
```

---

## Pattern 2 — Scheduled staleness audit (cron)

Weekly audit emits owner notifications.

### GitHub Actions cron

```yaml
# .github/workflows/staleness-audit.yml
name: Staleness Audit

on:
  schedule:
    - cron: '0 9 * * MON'  # Monday 09:00 UTC
  workflow_dispatch:

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run staleness audit
        run: scripts/staleness-audit.py --output reports/
      - name: Email owners
        run: scripts/email-owners.py --report reports/staleness.json
```

### Audit script outline

```python
#!/usr/bin/env python3
"""Scan canonical entities; identify stale; emit per-owner digest."""
import yaml, glob, datetime, json

def is_stale(entity, rules):
    rule = rules.get((entity["domain"], entity["type"]))
    if not rule:
        return False
    cutoff = datetime.date.today() - datetime.timedelta(days=rule["days"])
    return entity["updated"] < cutoff

stale = [
    yaml.safe_load(open(p).read().split("---")[1])
    for p in glob.glob("entities/**/*.md", recursive=True)
    if is_stale(yaml.safe_load(open(p).read().split("---")[1]), STALENESS_RULES)
]

# Group by owner
by_owner = {}
for e in stale:
    by_owner.setdefault(e["owner"], []).append(e)

# Emit per-owner digest
json.dump(by_owner, open("reports/staleness.json", "w"), indent=2)
```

### Email script outline

```python
#!/usr/bin/env python3
"""Email each owner their staleness digest."""
import json, smtplib
from email.message import EmailMessage

data = json.load(open("reports/staleness.json"))

TEMPLATE = """Hi {owner},

The following {count} entities you own are past their staleness
review window:

{entities}

To acknowledge as up-to-date: <link>/ack
To update: <repo>/edit
To sunset: <repo>/sunset

— Enterprise KB Bot
"""

for owner, entities in data.items():
    msg = EmailMessage()
    msg["From"] = "kb-bot@example.com"
    msg["To"] = owner
    msg["Subject"] = f"[KB] {len(entities)} entities you own are due for review"
    msg.set_content(TEMPLATE.format(
        owner=owner,
        count=len(entities),
        entities="\n".join(f"- {e['id']} (last: {e['updated']})" for e in entities),
    ))
    # Send via SMTP / SES / SendGrid
    ...
```

---

## Pattern 3 — Sunset enforcement (cron)

Monthly job applies sunset to qualifying entities.

```yaml
on:
  schedule:
    - cron: '0 9 1 * *'  # 1st of month, 09:00 UTC
  workflow_dispatch:

jobs:
  sunset:
    runs-on: ubuntu-latest
    steps:
      - name: Apply sunset to qualifying entities
        run: scripts/sunset-enforcement.py --dry-run-first
      - name: Create PR with sunset changes
        run: scripts/create-sunset-pr.sh
```

Sunset always opens a PR (never auto-merge), so a human reviews
which entities are being sunset before it's applied.

---

## Pattern 4 — Unowned governance (cron)

Weekly job surfaces unowned entities to governance authority.

```python
unowned = [
    e for e in entities
    if e["owner_status"] == "unassignable_for_7_days_plus"
]

if unowned:
    notify_governance(
        recipients=GOVERNANCE_AUTHORITY,
        subject=f"[KB] {len(unowned)} unowned entities need assignment or sunset",
        body=template.format(entities=unowned),
    )
```

---

## Pattern 5 — Post-merge search-index rebuild

After every merge, the search index re-indexes affected entities.

```yaml
# In the merge workflow
- name: Trigger search index rebuild
  run: |
    curl -X POST $SEARCH_INDEX_REBUILD_WEBHOOK \
      -H "Authorization: $SEARCH_INDEX_TOKEN" \
      -d '{"affected_entities": ${{ steps.merge.outputs.affected_ids }}}'
```

Incremental re-index (not full rebuild) — only embed + index the
entities that changed.

---

## Pattern 6 — Owner acknowledgement webhook

When an owner acknowledges via the digest's `<link>/ack`, the
acknowledgement updates the entity's `updated:` field (light-
weight; no content change).

```python
# Acknowledgement endpoint
@app.post("/ack/{entity_id}")
def acknowledge(entity_id: str, owner_email: str):
    entity = load_entity(entity_id)
    assert owner_email == entity["owner"]
    entity["updated"] = datetime.date.today().isoformat()
    save_entity(entity)
    commit_with_message(f"kb: ack staleness review for {entity_id} by {owner_email}")
    return {"status": "acknowledged"}
```

Lightweight ack vs full re-update is important: most stale-
review notifications don't actually require content change.

---

## Anti-patterns

- **Auto-applied sunset.** Without human review, occasionally
  the wrong entity gets sunset. Always PR.
- **Per-entity emails.** 100 stale entities → 100 emails →
  ignored. Aggregate to digest.
- **No dry-run before merge.** Merge that silently overwrites a
  recently-edited canonical entity. Always dry-run, surface,
  apply.
- **Webhook with no auth.** Search-index rebuild webhook needs
  authentication; otherwise anyone can trigger expensive
  re-index.
- **Cron schedule clustering.** All cron jobs at midnight → load
  spike. Stagger schedules.
