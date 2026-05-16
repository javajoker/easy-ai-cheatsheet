# KB Merge Report — <date>

**Version:** 1
**Merge date:** YYYY-MM-DD
**Operator:** <name or "knowledge-curator agent">
**Mode:** full re-merge | incremental | single-source refresh
**Conflict policy:** stop-on-conflict | auto-prefer-source
**Status:** dry-run | applied | reverted

---

## Summary

| Action | Count |
|---|---|
| Promoted (new canonical) | N |
| Updated (existing canonical) | M |
| Conflicts surfaced | K |
| Conflicts resolved | K (must equal above before apply) |
| Per-project only (didn't promote) | L |
| Aliases captured | Q |
| Cross-references rewritten | R |
| **Total candidates processed** | <total> |

---

## Sources processed

| Source | Path | Last-modified | Entities considered |
|---|---|---|---|
| `coolshell` KB | `github.com/x/coolshell/docs/knowledge-base/` | YYYY-MM-DD | N |
| `stardust` KB | `github.com/x/stardust/docs/knowledge-base/` | YYYY-MM-DD | M |
| Acme Eng Handbook | `books/acme-handbook.pdf` | YYYY-MM-DD | K |
| Memory: `project:*` | – | – | L |

---

## Promoted entities

| Entity ID | Domain | Sources merged | Owner | Notes |
|---|---|---|---|---|
| `auth-service` | products | coolshell-auth + stardust-auth | jane@ | aliases: Auth, Identity |
| `tenant` | terminology | coolshell-tenant + stardust-workspace | product-team@ | aliases: Workspace, Organisation, Account |
| `jwt-rotation-2025` | decisions | memory: stardust/jwt_rotation | security@ | promoted from decision memory |

---

## Updated entities

| Entity ID | Update | Source |
|---|---|---|
| `auth-service` | Added new source: latest stardust commit | stardust |
| `tenant` | Added alias: "Account" (from pricing docs) | stardust |

---

## Conflicts surfaced

### Conflict 1 — `user` definition

**Type:** Definition

- **Source A (`coolshell`):** *"User = anyone with an account (paid or free)."*
- **Source B (`stardust`):** *"User = paid customer only; free-tier accounts are 'prospects'."*

**Recommendation.** Source A — broader; aligned with platform-wide
usage. Source B's narrower meaning is product-specific; rename
B's entity to `paying-customer`.

**Resolution.** <user picked> — applied YYYY-MM-DD.

---

### Conflict 2 — `auth-service` ownership

**Type:** Field value

- **Source A (`coolshell` KB):** `owner: alice@example.com`
- **Source B (`stardust` KB):** `owner: bob@example.com`

**Recommendation.** Alice (per recent org chart memory; Bob left
2026-Q1).

**Resolution.** Owner = alice@example.com. Memory updated.

---

(Continue per conflict.)

---

## Per-project-only entities

(Entities that did not meet promotion criteria.)

| Entity | Source | Why not promoted | Recommendation |
|---|---|---|---|
| `coolshell-debug-tooling` | coolshell | Single-source; project-specific | Stays in source |
| `stardust-rtl-helpers` | stardust | Single-source; project-specific | Stays in source |

---

## Aliases captured

| Canonical | Aliases added |
|---|---|
| `tenant` | "Workspace", "Account" |
| `auth-service` | "Auth", "Identity Service" |

---

## Cross-references rewritten

| From | To | Source path |
|---|---|---|
| `/coolshell/kb/auth-service` | `/enterprise-kb/entities/products/auth-service` | `coolshell/docs/knowledge-base/services/users.md` |
| `/stardust/kb/workspace` | `/enterprise-kb/entities/terminology/tenant` | `stardust/docs/knowledge-base/concepts/multi-tenancy.md` |

**Cross-reference rewrite count:** R

---

## Source manifest updates

| Source | Change |
|---|---|
| Added | <list of new sources> |
| Removed | <list of sources no longer feeding the KB> |
| Updated | <list of sources whose location changed> |

---

## Validation

- [ ] All promoted entities have required base fields (id, name,
      domain, type, owner, status, classification, updated,
      created, sources).
- [ ] All promoted entities have domain-specific extra fields.
- [ ] No promoted entity has `classification: <blank>` (default-
      to-internal rejected).
- [ ] All cross-references resolve (no broken links).
- [ ] All conflicts resolved before apply.

---

## Apply / dry-run

- [ ] **Dry-run** completed — proposed changes surfaced to user.
- [ ] User approved at: YYYY-MM-DD.
- [ ] **Apply** completed — changes written to canonical
      `enterprise-kb/entities/`.

---

## Hand-off

- [ ] `enterprise-kb-search-index` re-indexing triggered.
- [ ] `enterprise-kb-access-control` verified classification on
      newly promoted entities.
- [ ] `enterprise-kb-refresh-policy` updated with next refresh
      schedule.
- [ ] Memory entry persisted: `kb_merge_<date>_v1`.

---

## Notes for next merge

<Anything worth carrying forward — patterns to watch for, sources
that need attention, conflicts likely to recur.>

---

## Change log

| Version | Date | Change | By |
|---|---|---|---|
| 1 | YYYY-MM-DD | initial merge report | <operator> |
