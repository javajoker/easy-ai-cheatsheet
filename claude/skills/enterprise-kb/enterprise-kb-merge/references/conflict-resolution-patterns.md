# Conflict Resolution Patterns

Common conflict types during enterprise-kb-merge + how they're
resolved.

## Type 1 — Definition conflict

**Pattern:** Same entity name; different semantic definitions
across sources.

**Example:**

- `user` in Source A: *"anyone with an account"*
- `user` in Source B: *"paid customer only"*

**Resolution options:**

1. **Pick the broader.** Promote broader def; rename narrower to
   a distinct entity (e.g. `paying-user`).
2. **Pick the narrower.** Promote narrower def; the broader
   becomes an unowned "concept" — likely needs renaming too
   (e.g. `account-holder`).
3. **Split into two entities.** Both become canonical with
   distinct names; explicit cross-references.

**Heuristic.** Pick option 3 unless one definition is clearly
authoritative (e.g. from a foundational decision memory). Don't
silently pick one and rename the other — surface both.

---

## Type 2 — Field-value conflict (current state)

**Pattern:** Same entity; different `owner` / `status` /
`classification` across sources.

**Example:**

- Source A: `owner: alice@`, `updated: 2025-08-22`
- Source B: `owner: bob@`, `updated: 2026-03-10`

**Resolution heuristic.** Most-recently-updated source typically
wins. But verify via authority — *"Did Bob actually become the
owner, or did stardust's KB drift?"*

**Common variant — both wrong.** Org chart changed; neither
source caught up. Resolution: look up current state from
authoritative source (org directory) and update both sources.

---

## Type 3 — Field-value conflict (historical state)

**Pattern:** Source A reflects historical state; Source B
reflects current.

**Example:**

- Source A: `tier_table: [free, pro, enterprise]` (from 2024)
- Source B: `tier_table: [free, starter, pro, enterprise]` (current)

**Resolution.** Promote current; historical state captured in
the entity's body under "Context" or "History" section, not in
required fields.

---

## Type 4 — Relation conflict

**Pattern:** One source has cross-references; another doesn't.

**Example:**

- Source A: `auth-service` relates to `[users-schema,
  jwt-rotation-decision]`
- Source B: `auth-service` relates to `[users-schema]` only

**Resolution.** **Additive merge** — combine relation lists.
Flag for review only if relations contradict (e.g. A says
`successor_id: foo`; B says `successor_id: bar`).

---

## Type 5 — Classification conflict

**Pattern:** Same entity classified differently across sources.

**Example:**

- Source A: `classification: internal`
- Source B: `classification: restricted`

**Resolution heuristic.** Default to **more restrictive** (Source
B's `restricted`). Loosening requires governance authority + a
documented reason. Tightening is a safe default.

---

## Type 6 — Sub-type conflict

**Pattern:** Same entity; different sub-types under the same
domain.

**Example:**

- Source A: `domain: decisions`, `type: architectural`
- Source B: `domain: decisions`, `type: strategic`

**Resolution heuristic.** The more *inclusive* sub-type usually
wins (architectural decisions often have strategic implications;
strategic decisions less often have architectural detail).

Verify the entity actually fits the chosen sub-type's required
extra fields.

---

## Type 7 — Alias conflict (entity already exists under another name)

**Pattern:** A candidate entity matches an existing canonical
entity's alias, but otherwise has different fields.

**Example:**

- Existing canonical: `tenant` (with alias `workspace`)
- Candidate: `workspace` (with different definition)

**Resolution.** Treat as **Type 1 (definition conflict)**. Surface
both definitions; user picks.

---

## Type 8 — Source disappeared

**Pattern:** A source the KB previously included no longer exists
(repo deleted, KB tree removed).

**Resolution.** Don't drop the canonical entities silently. Mark
the source as `removed` in the manifest; preserve canonical
entities. If the canonical entity's *only* source is now gone,
mark it for review — either find a new authoritative source or
sunset the entity.

---

## Type 9 — Bulk conflict (many entities all conflict)

**Pattern:** Two sources have systematically different
conventions (e.g. one always uses `userId`; other uses `user_id`).

**Resolution heuristic.** Don't resolve entity-by-entity — that's
hundreds of identical decisions. Instead:

1. Surface the convention conflict to the user.
2. User picks the canonical convention.
3. Apply rename across all affected entities in one pass.
4. Capture as a `terminology/canonical` decision so future
   sources can pre-align.

---

## Auto-prefer-source mode

Some refreshes (especially low-stakes incremental refreshes) can
auto-resolve conflicts by preferring a designated authoritative
source. Configure per source in the source manifest:

```yaml
sources:
  - name: coolshell
    authority_class: high     # wins conflicts against lower
  - name: stardust
    authority_class: medium
  - name: extracted-handbook
    authority_class: low      # loses conflicts
```

**Use auto-prefer-source sparingly.** It silences valuable
signal. The default `stop-on-conflict` mode is safer.

---

## Documentation

Every resolved conflict is documented in the merge report's
"Conflicts surfaced" section with:

- Conflict type (from above).
- The two (or more) interpretations + sources.
- The resolution + rationale.
- Approver (the user or named authority).
- Date.

This documentation is the audit trail. Future merges reference
it to avoid re-deciding the same questions.
