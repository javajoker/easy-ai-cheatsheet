# Changelog Scan Vocabulary

Classification rules for breaking changes encountered during a
dependency upgrade.

## Four classes (use these labels, not free-form)

### mechanical

API renamed, signature changed, but **same semantic behaviour**.

**Examples:**

- `foo.doBar()` → `foo.do_bar()` (case convention change).
- `import { Bar } from 'foo'` → `import { Bar } from 'foo/bar'`.
- Constructor signature reordered.

**Action:** codemod (jscodeshift / libCST / gofmt-style) or
mechanical find-replace. Low risk; deterministic.

---

### behavioural

API surface same, but **different runtime behaviour**.

**Examples:**

- Default config flipped from `eager: true` to `eager: false`.
- Error format changed from string to structured object.
- Timeout default reduced from 30s to 5s.
- Sort order changed from stable to unstable.

**Action:** review every call site; update tests to expect new
behaviour; fix application code that relied on old behaviour.
Medium risk; requires understanding intent at each call site.

---

### removed

API surface deleted entirely.

**Examples:**

- Function deleted; replaced by alternative.
- Class deprecated last major; gone this major.
- Module dropped from public API.

**Action:** find every reference; rewrite to use replacement; if
no replacement, redesign affected code. High risk; touches code
shape.

---

### deprecated

Works now; will be removed in a **future** major.

**Examples:**

- "This will be removed in v6" (we're upgrading to v5).
- Warning message in console / logs.

**Action:** **track for the next upgrade; do not block this one.**
Add to backlog. Optionally: capture in `INSTRUCTIONS/projects/<slug>/`
as a known future task.

---

## Per-change scan template

For each breaking change in the upstream changelog:

```markdown
| # | Change (from changelog) | Class | Affects this project? | Action |
|---|---|---|---|---|
| C1 | `fetch()` default timeout reduced to 5s | behavioural | YES — auth callback takes 8s in prod | Increase timeout explicitly; verify in test matrix |
| C2 | `legacyMode` config removed | removed | YES — we use it for X | Migrate to new approach; rewrite call sites |
| C3 | Deprecation warning on `oldThing()` | deprecated | YES — used in 12 places | Track for next major; do not block this upgrade |
| C4 | API rename `fooBar` → `foo_bar` | mechanical | YES | Codemod |
```

## Scan discipline

1. **Read the changelog from current to target version**, not
   just the latest entry.
2. **Per change, ask "does this affect us?"** — many breaking
   changes won't apply to your project. Don't pre-fix what isn't
   broken.
3. **Cite location** when "yes" — file + line range of affected
   code.
4. **Don't classify on intent** — classify on the change shape.
   A renamed-but-same-behaviour change is mechanical even if
   the rename was philosophically motivated.

## Output

The classified table becomes the basis for the test matrix and
the migration code in `arch-dependency-upgrade`'s plan.
