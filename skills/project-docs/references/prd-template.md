# PRD Template Reference

Use this exact structure when generating PRD.md. Replace all {placeholders}.

---

```markdown
# {Project Name} — Product Requirements Document

**Version**: 1.0
**Date**: {today}
**Status**: Draft

---

## 1. Executive Summary

{1 paragraph: what this product is, who it's for, what problem it solves,
why it should exist. End with the one-sentence value proposition.}

---

## 2. Goals and Non-Goals

### 2.1 Goals (in scope)
- {Specific, measurable goal 1}
- {Specific, measurable goal 2}
- {...}

### 2.2 Non-Goals (explicitly out of scope)
- {Thing we are NOT doing in v1}
- {Future feature deferred to v2}

---

## 3. User Personas

### 3.1 {Persona Name 1, e.g. "IP Creator"}
- **Background**: {who they are, what they bring}
- **Goals**: {what they want to accomplish}
- **Pain points**: {what's hard for them today}
- **Technical comfort**: {low/medium/high}

### 3.2 {Persona Name 2}
{Same structure}

{Repeat for every distinct user role.}

---

## 4. User Stories

Group stories by persona. Use the format:
> As a {persona}, I want to {action}, so that {outcome}.

### 4.1 {Persona Name 1}
- US-1.1: As an IP creator, I want to register my IP with custom license terms,
  so that I retain control over how my work is reused.
- US-1.2: As an IP creator, I want to set a revenue share percentage, so that
  I'm compensated when secondary creators sell derivatives.
- {...}

### 4.2 {Persona Name 2}
- {...}

---

## 5. Feature List

| ID | Feature | Description | Priority | Persona |
|----|---------|-------------|----------|---------|
| F-001 | {Feature name} | {1-line description} | P0 | {persona(s)} |
| F-002 | {...} | {...} | P0 | {...} |
| F-003 | {...} | {...} | P1 | {...} |

**Priority key:**
- **P0** — Required for v1 launch. Removing it kills core value.
- **P1** — Important but can be deferred to fast-follow if needed.
- **P2** — Nice to have. Polish, optimisation, or edge case.

Include EVERY feature visible in the prototype, plus the inferred ones:
- Authentication (sign up / sign in / password reset)
- Profile management
- Notifications (in-app + email)
- Search / filter
- Settings
- Help / support

---

## 6. Business Rules

### 6.1 Permissions and Eligibility
- {Rule 1: who can do what}
- {Rule 2}

### 6.2 Pricing and Fees
- {Platform fee structure}
- {Revenue split rules}
- {Refund policy}

### 6.3 Validation and Limits
- {Field length limits}
- {File size limits}
- {Rate limits per role}

### 6.4 Workflow Rules
- {State transitions: e.g. "An order goes from Created → Paid → Shipped → Delivered"}
- {Approval workflows: e.g. "Listings must be admin-approved before going live"}

---

## 7. Success Metrics

How we'll know this is working post-launch:

| Metric | Target | Measurement |
|--------|--------|-------------|
| {Activation: % of new users who complete first action} | {>40%} | {Mixpanel funnel} |
| {Retention: 7-day return rate} | {>30%} | {Cohort analysis} |
| {GMV / revenue per active user} | {>$X} | {Stripe data} |

---

## 8. Risks and Open Questions

### 8.1 Technical Risks
- {Risk 1: e.g. "Reliance on third-party API X — what if it goes down?"}

### 8.2 Product Risks
- {Risk 2: e.g. "Two-sided marketplace cold-start problem"}

### 8.3 Open Questions (need decisions before code)
- {Q1: e.g. "Custodial or non-custodial wallet?"}
- {Q2: e.g. "Self-serve or admin-approved listings?"}

---

## 9. Glossary

| Term | Definition |
|------|------------|
| {Domain term} | {Plain-language definition} |
```
