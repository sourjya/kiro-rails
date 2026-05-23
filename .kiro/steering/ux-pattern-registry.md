---
inclusion: manual
---

# UX Pattern Registry

Reference patterns for common screen types. Load with `/ux-pattern-registry` when designing or reviewing UI.

Before implementing any major screen, find the matching pattern below. If no pattern matches, propose a new entry before coding.

---

## Task Detail View

**Use when:** User needs to read, edit, comment, or inspect a single task/item.

**Layout:**
- Large title at top, full width
- Metadata (status, assignee, dates) secondary — compact row or sidebar
- Description and comments get primary content space (dominant height)
- Activity/comments must not be visually minimized

**Rules:**
- Section controls adjacent to section headers (leading or beside)
- Content canvas gets 60%+ of viewport height
- Comments rendered at body text size (15-16px), not small/muted
- Subtle selection state — no thick decorative borders

**Reference:** Asana task detail, Linear issue detail, Notion page

---

## Data Table / List View

**Use when:** User scans, filters, sorts, and selects from many items.

**Layout:**
- Compact density acceptable
- Column headers aligned with cell content (same layout strategy)
- Bulk actions near selection indicator
- Filters above or beside the table, not buried

**Rules:**
- Row height consistent — no variable-height rows in scan mode
- Clickable rows have hover state
- Header and body use identical grid/flex strategy (no alignment drift)
- Pagination or infinite scroll — never unbounded lists

**Reference:** GitHub issues list, Linear board, Airtable grid

---

## Form / Settings Page

**Use when:** User fills in or modifies structured data.

**Layout:**
- Spacious — generous vertical gaps between field groups
- Labels above inputs (not beside, unless very short forms)
- Primary action (Save/Submit) at bottom, visually prominent
- Destructive actions (Delete) separated and de-emphasized

**Rules:**
- Field groups have clear section headers
- Validation errors inline, adjacent to the field
- No horizontal scrolling — form fits viewport width
- Tab order follows visual order

**Reference:** GitHub settings, Stripe dashboard settings

---

## Dashboard / Overview

**Use when:** User needs a high-level summary with drill-down capability.

**Layout:**
- Cards or panels for distinct metric groups
- Most important metrics largest/topmost
- Secondary details accessible via click, not shown upfront

**Rules:**
- No more than 7±2 top-level items visible without scrolling
- Each card has a clear label and one primary number/status
- Drill-down affordance visible (arrow, link, hover state)
- Empty states for cards with no data

**Reference:** Vercel dashboard, Datadog overview, GitHub repo home

---

## Modal / Dialog

**Use when:** User must complete a focused sub-task without losing page context.

**Layout:**
- Centered, max-width 600px for forms, 800px for content
- Title + close button at top
- Primary action bottom-right, cancel bottom-left
- Content scrolls if needed, buttons stay fixed

**Rules:**
- Focus trapped inside modal
- Escape closes (unless destructive action in progress)
- Backdrop click closes (unless form has unsaved changes)
- No nested modals — use a drawer or navigate instead

**Reference:** GitHub "New issue" dialog, Linear "Create issue"

---

## Empty State

**Use when:** A screen or section has no data to display.

**Layout:**
- Centered in the content area
- Icon or illustration (optional, subtle)
- Clear message: what this area is for + what to do next
- Primary action button to create/add the first item

**Rules:**
- Never show a blank white space with no explanation
- Message uses plain language, not technical jargon
- Action button matches the primary creation flow
- Don't show filters/sort controls when there's nothing to filter

**Reference:** Notion empty page, Linear empty project
