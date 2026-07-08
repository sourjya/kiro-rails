---
inclusion: manual
description: Console-idiom UX rubric — 9 check families with severity scoring for data-dense admin/SaaS interfaces. Load with /ux-console-idiom when reviewing or generating UI.
---

# UX Console-Idiom Rubric

A checkable UX quality rubric for **console-style applications** — admin panels, dashboards, SaaS control planes, and data-dense internal tools. Each check has a unique ID, severity, and a binary pass/fail criterion.

**Load this file** when reviewing, auditing, or generating UI for console-type applications. It layers on top of WCAG 2.2 AA and Nielsen's 10 heuristics as the **house standard** — specific where they are general.

**Customize:** Override threshold values in `user-project-overrides.md` under the Design Tokens section. The IDs and severity model are fixed; the numeric thresholds are team-configurable.

---

## Scoring Model

- **Starting score:** 100 per page/screen
- **Sev-1 (blocking/data-loss/misleading):** −15 each
- **Sev-2 (idiom/flow break):** −5 each
- **Sev-3 (polish):** −1 each
- **Ship gate:** zero Sev-1 findings AND no page below 70

### Severity Definitions

| Level | Meaning | Examples |
|-------|---------|----------|
| Sev-1 | Data loss, user blocked, or actively misleading | Modal with no Escape/close; save silently fails; destructive action without confirmation |
| Sev-2 | Breaks the console idiom or interrupts task flow | Multiple save patterns on one page; unreadable density; broken navigation state |
| Sev-3 | Polish issue, cosmetic inconsistency | Inconsistent border-radius; orphaned label; extra font weight |

---

## D — Density & Type

Controls typographic consistency and information density.

| ID | Check | Sev | Criterion |
|----|-------|-----|-----------|
| D-1 | Body text size | 2 | Body text within the configured range (default: 13–14px). Outliers flagged. |
| D-2 | Font weight count | 2 | No more than 2 font weights in use (default: 400, 600). Each additional weight is a finding. |
| D-3 | Heading hierarchy | 3 | Heading sizes decrease monotonically (h1 > h2 > h3). No size inversions. |
| D-4 | Line height | 3 | Body line-height between 1.4–1.6. Below 1.3 is a Sev-2 density violation. |
| D-5 | Micro-label variant | 3 | Badges, tags, and status pills use a dedicated smaller type size, not body text. |

---

## S — Surfaces & Layout

Controls spatial organization and container usage.

| ID | Check | Sev | Criterion |
|----|-------|-----|-----------|
| S-1 | Content primacy | 2 | Primary content (forms, descriptions, data) gets ≥60% of viewport height. Metadata is secondary. |
| S-2 | Section control placement | 2 | Section actions are adjacent to (leading or beside) their section header. Never trailing-far-right unless page-level. |
| S-3 | Consistent card/panel usage | 3 | Cards/panels of the same type use identical padding, border-radius, and shadow. |
| S-4 | Scroll containment | 2 | Each scrollable region is independently scrollable. No double-scrollbar or body-scroll-lock-while-panel-scrolls. |
| S-5 | Responsive breakpoints | 3 | Layout does not break or overflow between configured breakpoints. |

---

## R — Read-First Editing

Controls the inline-edit and detail-view patterns.

| ID | Check | Sev | Criterion |
|----|-------|-----|-----------|
| R-1 | Read state is default | 2 | Detail views render in read mode first. Edit mode requires an explicit user action. |
| R-2 | Edit affordance visible | 2 | The path from read to edit is discoverable within 1 click/tap from the read view. |
| R-3 | Cancel discards cleanly | 2 | Cancelling an edit restores the exact prior read state. No partial saves, no stale form data. |
| R-4 | Dirty-state indicator | 3 | When a form has unsaved changes, a visual indicator (dot, label, or disabled-nav warning) is visible. |

---

## V — Save Model

Controls how mutations are committed and confirmed.

| ID | Check | Sev | Criterion |
|----|-------|-----|-----------|
| V-1 | One save pattern per app | 2 | The entire application uses ONE save pattern (explicit Save button, auto-save, or inline confirm). Never mix. |
| V-2 | Save confirmation | 2 | Every successful save produces visible feedback (toast, inline check, status change) within 300ms. |
| V-3 | Save failure is loud | 1 | A failed save MUST surface an error the user can act on. Silent save failure is a Sev-1. |
| V-4 | Pending state during save | 3 | The save trigger shows a loading/pending state while the operation is in flight. No stale-looking button. |

---

## T — Tables & Lists

Controls data-grid and list-view patterns.

| ID | Check | Sev | Criterion |
|----|-------|-----|-----------|
| T-1 | Header–body alignment | 2 | Table headers and body cells use the same layout strategy (grid or flex with identical columns). No alignment drift. |
| T-2 | Row height consistency | 3 | All rows in a scan-mode table have identical height. Variable-height rows break scan flow. |
| T-3 | Empty state | 2 | A table/list with zero items shows a purposeful empty state (message + primary action), never a blank white space. |
| T-4 | Pagination or virtual scroll | 2 | Lists with >50 items are paginated or virtualized. Never render unbounded DOM lists. |
| T-5 | Sort/filter discoverability | 3 | Sort and filter controls are visible without interaction (not hidden behind a menu) on data tables. |

---

## E — Empty States & Feedback

Controls system status communication.

| ID | Check | Sev | Criterion |
|----|-------|-----|-----------|
| E-1 | Loading state | 2 | Every async-loaded section shows a skeleton or spinner. No blank flash before content appears. |
| E-2 | Error state | 2 | Every section that can fail shows a meaningful error (what happened + what to do next). No raw exception messages. |
| E-3 | Empty state with action | 2 | Empty sections explain what the area is for AND provide a primary creation action. |
| E-4 | Optimistic feedback | 3 | Actions that will succeed >99% of the time may show instant feedback (optimistic UI), with rollback on failure. |
| E-5 | Progress for long operations | 2 | Operations taking >2s show progress (determinate if possible, indeterminate otherwise). |

---

## C — Copy & Correctness

Controls text quality and data display.

| ID | Check | Sev | Criterion |
|----|-------|-----|-----------|
| C-1 | Pluralization | 2 | All countable nouns pluralize correctly ("1 item" / "3 items", never "1 items"). |
| C-2 | Label/value pairing | 3 | Every data value has an adjacent label. No orphaned numbers or strings without context. |
| C-3 | Truncation with tooltip | 3 | Text that truncates (ellipsis) reveals full content on hover/focus via a tooltip or expansion. |
| C-4 | Consistent date format | 3 | A single date format is used throughout the app (configure in design tokens). |
| C-5 | User-generated names displayed as-is | 2 | User-provided names (project names, labels) display in their original case. Never slug-case or auto-transform. |

---

## A — Accessibility & States

Controls WCAG compliance and interactive state coverage.

| ID | Check | Sev | Criterion |
|----|-------|-----|-----------|
| A-1 | Focus management | 1 | Modals and dialogs trap focus on open AND return focus to the trigger on close. Violation is Sev-1 if it blocks task completion. |
| A-2 | Contrast ratio | 2 | Text meets WCAG 2.2 SC 1.4.3 (4.5:1 normal, 3:1 large). UI components meet SC 1.4.11 (3:1). |
| A-3 | Keyboard navigation | 1 | Every interactive element is reachable and operable via keyboard. Tab order follows visual order. |
| A-4 | Escape closes overlays | 1 | Pressing Escape closes the topmost overlay (modal, dropdown, drawer). Missing Escape is Sev-1 if it traps the user. |
| A-5 | Named form controls | 2 | Every `<input>`, `<select>`, and `<textarea>` has a visible or aria-label. No unlabelled controls. |
| A-6 | Disabled state clarity | 3 | Disabled controls are visually distinct (opacity, cursor) and have a title/tooltip explaining WHY they are disabled. |

---

## K — Consistency & Tokens

Controls design-system adherence and visual consistency.

| ID | Check | Sev | Criterion |
|----|-------|-----|-----------|
| K-1 | Border-radius set | 3 | At most N distinct border-radius values in use (default: 2). Additional values are findings. |
| K-2 | Color palette adherence | 2 | All colors used are from the configured design token palette. Off-palette colors are findings. |
| K-3 | Spacing scale | 3 | Padding and margin values align to the configured spacing scale (e.g., 4px increments). |
| K-4 | Icon style consistency | 3 | All icons use the same style family (outline OR filled, not mixed). |
| K-5 | Active/selected state | 2 | The current tab, nav item, or selection uses a consistent active-state treatment across the app. |

---

## Using This Rubric

### In review prompts

Reference this file and require findings to carry a rubric ID + severity:

```
Finding: D-2 (Sev-2) — 4 font weights in use (400, 500, 600, 700). Expected max 2.
Fix: Remove 500 and 700; consolidate to 400/600.
```

### In generation-time steering

Reference the design tokens in `user-project-overrides.md` to prevent writing non-compliant UI in the first place (prevention > detection).

### In CI/report gates

Use the scoring model: a page with one Sev-1 finding automatically fails. A page at 65/100 fails. The report must carry the rubric ID for traceability.

### Evidence

Findings SHOULD include quantitative evidence from `scripts/style-survey.js` (computed-style census) or accessibility-tree inspection. Screenshot-only findings are provisional until confirmed by live interaction.

---

## Cross-references

- `user-project-overrides.md` — team-specific threshold overrides (font size, weight count, radii count, spacing scale)
- `ux-pattern-registry.md` — reference layout patterns for common screen types
- `review-ux-audit.md` — review prompt that scores against this rubric
- `review-ux-live.md` — live browser-walk protocol using this rubric
- `scripts/style-survey.js` — quantitative evidence collection script
