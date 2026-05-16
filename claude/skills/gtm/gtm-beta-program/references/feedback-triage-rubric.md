# Feedback Triage Rubric

Every piece of beta feedback classified into one of four classes.
Classifying takes <60 seconds; routing takes longer if the rubric
isn't clear.

## The four classes

### 🐛 Bug — software does X but shouldn't

**Signal phrases:**

- "It broke when…"
- "I got an error…"
- "The button does nothing."
- "It says A but I expected B."
- "It worked yesterday but not today."

**Action:**

- File in issue tracker.
- Severity per standard rubric (P0–P3).
- Acknowledge to reporter in 48h.
- Close the loop when shipped or won't-fix.

**Owner:** Engineering (via reporter / triage rotation).

---

### 📐 Gap — feature PRD missed

**Signal phrases:**

- "I expected the product to do X."
- "Why doesn't it have X?"
- "I have to do X manually."
- "[Competitor] does X."

**Action:**

- File as feature request.
- PM reviews for inclusion in PRD.
- If material to value prop → consider for current beta phase.
- If non-material → log for post-GA roadmap.
- Acknowledge to reporter; explain decision.

**Owner:** Product (via PM triage).

---

### 🔄 Misalignment — expected ≠ shipped

**Signal phrases:**

- "I thought it would X but it's Y."
- "I don't understand what this does."
- "The docs said X but it does Y."
- "Why does it work that way?"

**Action:**

- **Don't ship a code change.** This is a docs / copy / UI issue.
- Update help docs / pricing copy / feature description.
- Consider in-app onboarding adjustment.
- Acknowledge to reporter.

**Owner:** Product Marketing / docs lead.

---

### 💭 Wishlist — "would be nice"

**Signal phrases:**

- "It would be cool if…"
- "Have you thought about adding X?"
- "Some day, X would be great."
- "We don't need it today, but…"

**Action:**

- Log in roadmap candidate list.
- Don't promise.
- Acknowledge to reporter; thank for the input.
- Periodic prioritisation review.

**Owner:** PM (via long-term roadmap process).

---

## Classifying borderline cases

### Bug vs Misalignment

If the product does what the spec says (just not what the user
expected), it's **misalignment** — fix the docs, not the code.

### Bug vs Gap

If the product is missing required functionality entirely, it's
a **gap** — file as a feature request, not a bug.

### Gap vs Wishlist

If the gap blocks the user from achieving the use case the
positioning brief promised, it's a **gap** (prioritise).

If the user can already achieve their use case but wants
additional capability, it's a **wishlist**.

### Multiple classes per item

One feedback item can span multiple classes. Triage each part
separately. Example:

> "The signup form crashes when I use my email (bug). Also, why
> do you require my phone number? (misalignment — we should
> explain) Also, you should support SSO (wishlist)."

→ 3 separate items, 3 separate classes.

---

## Triage process

For each new feedback item:

1. **Read** the report (1 min).
2. **Classify** into one of the four classes (30 sec).
3. **Route** to owner per rubric (30 sec).
4. **Acknowledge** to reporter within 48h (1 min).

Triage capacity per week ≈ 50–100 items per triager. Beta with
20+ active users typically needs daily triage rotation.

---

## Acknowledgement templates

### Bug

> Thanks for the report! Tracking this as <issue-id>. Severity
> P<N>. We'll update you when it ships.

### Gap

> Thanks for the suggestion. We're <considering / scheduling /
> not pursuing> this — <one-line reason>. <Link to public
> roadmap if applicable.>

### Misalignment

> Good signal — we'll update <docs / copy / UI>. Thanks for
> flagging.

### Wishlist

> Great idea. We've logged this in our roadmap candidates.
> Won't commit to a timeline but will keep you posted if it
> moves up.

---

## Weekly triage report

The triager(s) emit a weekly summary:

```
WEEK OF YYYY-MM-DD
==================

Total feedback items: N

By class:
  🐛 Bugs:          M
  📐 Gaps:          K
  🔄 Misalignment:  J
  💭 Wishlist:      L

Top 5 themes:
  1. <theme>: N items
  2. <theme>: M items
  ...

Closed-loop:
  - Acknowledged within 48h: N% (target: 100%)
  - Resolved this week: M items

Carry-over to next week: <count>

Notable surprises:
  <anything worth team-wide discussion>
```

---

## Anti-patterns

- ❌ No triage — feedback sits in 6 channels untouched.
- ❌ Classifying everything as a wishlist (avoidance).
- ❌ Classifying misalignment as a bug (wasting eng time).
- ❌ No acknowledgement (reporter learns we don't listen).
- ❌ "We'll consider it" with no follow-up.
- ❌ Triage by gut feel without rubric (inconsistent decisions).
