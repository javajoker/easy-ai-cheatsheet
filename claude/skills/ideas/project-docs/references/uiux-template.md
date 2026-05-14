# UI/UX Spec Template Reference

Use this exact structure when generating UIUX_SPEC.md.

---

```markdown
# {Project Name} — UI/UX Design Specification

**Version**: 1.0
**Date**: {today}
**Companion docs**: PRD.md, TECH_DESIGN.md

---

## 1. Design Principles

3–5 guiding principles that all design decisions must respect:
1. **{Principle 1, e.g. "Trust through transparency"}** — {what this means in practice}
2. **{Principle 2, e.g. "Mobile-first"}** — {what this means in practice}
3. **{...}**

---

## 2. Information Architecture

### 2.1 Sitemap

\`\`\`
/
├── (public)
│   ├── /                          # Landing
│   ├── /catalog                   # Browse all items
│   ├── /catalog/:id               # Item detail (public)
│   ├── /verify/:code              # Authenticity check
│   └── /auth/{signin,signup}
├── (authenticated, role: creator)
│   ├── /dashboard
│   ├── /my-items
│   ├── /my-items/:id
│   ├── /my-items/new
│   └── /earnings
├── (authenticated, role: buyer)
│   ├── /dashboard
│   ├── /orders
│   ├── /orders/:id
│   └── /cart
└── (admin)
    ├── /admin/dashboard
    ├── /admin/users
    ├── /admin/moderation
    └── /admin/disputes
\`\`\`

### 2.2 Navigation Patterns
- {Top nav: persistent, contains logo + main sections + user menu}
- {Mobile nav: bottom tab bar with 4-5 primary destinations}
- {Breadcrumbs: on all detail views}

---

## 3. View Specifications

ONE SECTION PER VIEW. Use this template for every view:

### 3.X — {View Name}

- **Path**: `/path/to/view`
- **Purpose**: {1 sentence}
- **Persona(s)**: {who uses it}
- **Primary actions**: {what the user can do here}

**Layout**:
- Header: {what's in the header}
- Body: {main content area description}
- Sidebar (if any): {what's in the sidebar}
- Footer (if any): {what's in the footer}

**Components used**:
- {ComponentName}: {purpose}
- {ComponentName}: {purpose}

**Data displayed**:
- {field1}: {format / source}
- {field2}: {format / source}

**States**:
- **Empty**: {what shows when there's no data}
- **Loading**: {skeleton or spinner pattern}
- **Error**: {error UI and recovery options}
- **Success**: {confirmation pattern}

**Mobile differences**:
- {How does this view change on small screens?}

**Linked from**: {which other views link here}
**Links to**: {which views this view links to}

---

{Repeat the section above for EVERY view in the prototype}

---

## 4. Missing Views to Add

Views the prototype didn't include but the PRD requires:

### 4.1 {Missing view name}
**Why needed**: {which user story / feature requires this}
{Then full view spec as in section 3}

Common missing views to check for:
- Forgot password / reset password
- Email verification
- Order detail (if there's an order list)
- Item detail public-facing version (if only the editing view exists)
- 404 / error pages
- Empty state of any list view
- Confirmation / success pages after key actions
- Dispute / report submission flow
- Account deletion / data export (GDPR)

---

## 5. Component Library

Shared components used across views:

### 5.1 Button
- Variants: primary, secondary, danger, ghost
- Sizes: sm, md, lg
- States: default, hover, focus, active, disabled, loading

### 5.2 Card
- Variants: default, interactive (clickable), highlighted
- Slots: header, body, footer

### 5.3 Form Components
- TextInput, Textarea, Select, Checkbox, Radio, FileUpload, DatePicker
- Validation states: default, error (with message), success

### 5.4 Modal / Dialog
- Sizes: sm, md, lg, fullscreen on mobile
- Patterns: confirmation, form, info, destructive action

### 5.5 Table / List
- Sortable columns
- Pagination (or infinite scroll)
- Empty state
- Loading skeleton

### 5.6 Notification / Toast
- Variants: info, success, warning, error
- Auto-dismiss vs persistent

### 5.7 Badge / Chip
- For status indicators, role labels, categories

---

## 6. User Flows

ONE SECTION PER FLOW. Document the happy path + key alternates.

### 6.1 {Flow name, e.g. "Creator registers an IP"}

**Persona**: Creator
**Trigger**: User clicks "Register IP" button on dashboard

**Happy path**:
1. User clicks "Register IP" → navigates to `/my-items/new`
2. Fills form (title, description, content upload, license terms)
3. Clicks "Submit"
4. System validates → loading state shown
5. Success → navigates to `/my-items/:id` with success toast
6. New IP appears in `/my-items` list with "Pending Review" badge

**Alternate paths**:
- **Validation error**: Form shows inline errors, user fixes, retries
- **Upload failure**: Error toast with retry button
- **Network error**: Offline banner, draft saved locally

**API calls** (for tech design alignment):
- `POST /api/ip-assets` (multipart with file)
- `GET /api/ip-assets/:id` (after redirect)

---

{Repeat for every primary flow}

---

## 7. Accessibility Requirements

- **WCAG target**: 2.1 Level AA
- **Colour contrast**: ≥ 4.5:1 for normal text, ≥ 3:1 for large text
- **Keyboard navigation**: all interactive elements reachable via Tab, primary actions
  via Enter, dismiss via ESC
- **Focus indicators**: visible focus ring on all focusable elements
- **Screen reader**: aria-label on all icon-only buttons; semantic HTML throughout
- **Form errors**: announced via aria-live, associated with inputs via aria-describedby
- **Reduced motion**: respect prefers-reduced-motion media query

---

## 8. Visual Design Tokens

(Brief — full design system can be elaborated later)

- **Colour palette**: primary, secondary, accent, semantic (success, warning, danger,
  info), neutrals (backgrounds, borders, text)
- **Typography**: 1 sans-serif family (e.g. Inter); 5 sizes (xs, sm, base, lg, xl, 2xl);
  3 weights (normal, medium, semibold)
- **Spacing**: 4px grid (4, 8, 12, 16, 24, 32, 48, 64)
- **Radius**: sm (4px), md (8px), lg (16px), full
- **Shadows**: subtle elevation steps (sm, md, lg)
- **Breakpoints**: sm 640, md 768, lg 1024, xl 1280

---

## 9. Localisation Notes

- **Default locale**: en
- **Additional locale**: zh-TW
- **Text expansion**: Chinese text is typically 50–70% of equivalent English by char
  count. Allow flexibility in button widths and headings.
- **Date / number formatting**: localised via Intl
- **Currency**: display alongside locale-appropriate format
```
