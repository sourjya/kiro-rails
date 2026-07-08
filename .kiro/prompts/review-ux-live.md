---
name: ux-live
description: >
  Live browser-walk UX review using the console-idiom rubric. Requires a
  browser MCP (Playwright, Chrome DevTools, or equivalent). Walks each
  page/route with a 9-step protocol, collects quantitative evidence, and
  produces a scored report with rubric IDs.
inclusion: manual
---

# Live UX Review — Browser-Walk Protocol

A structured protocol for reviewing a running application's UX via browser
automation. Each page is walked with 9 steps that produce evidence for
scoring against `.kiro/steering/ux-console-idiom.md`.

**Prerequisites:**
- A browser MCP (Playwright MCP, Chrome DevTools MCP, or BrowserTools MCP)
- The application running and accessible (local or deployed)
- `scripts/style-survey.js` available for injection

**Before you start:** Load `.kiro/steering/ux-console-idiom.md` for the
rubric definitions and scoring model.

---

## Side-Effect Boundary — NON-NEGOTIABLE

During a live review, you are an **observer only**. Do NOT:
- Submit forms (except safe dirty-state probes — see Step 5)
- Click delete, remove, or destructive action buttons
- Send messages, emails, or notifications
- Log out (you may lose session state)
- Create, modify, or save data
- Accept or dismiss important system dialogs that affect state

Safe interactions ONLY:
- Navigation (click links, tabs, breadcrumbs)
- Hover and focus (for tooltip/state discovery)
- Type into fields WITHOUT submitting (dirty-state probe)
- Press Escape (overlay dismissal test)
- Scroll (full-page capture)
- Open dropdowns and menus (read-only discovery)

If unsure whether an action is safe, **do not take it**. Report it as
"unverifiable without write access" in the findings.

---

## Per-Page Protocol (9 Steps)

Run these 9 steps for each page or major route in the application.

### Step 1: Verify Session State

Before interacting, confirm:
- URL is correct (not redirected unexpectedly)
- Authentication state is valid (user is logged in if required)
- The page has fully loaded (no spinners, no partial content)

If the page redirected or shows an error, document it as a finding
before proceeding.

### Step 2: Screenshot + Accessibility Tree

Capture two things simultaneously:
1. A full viewport screenshot (evidence for visual findings)
2. The accessibility tree or ARIA snapshot (evidence for A-family checks)

Note: A screenshot alone cannot prove interactive behavior. It can only
prove visual state at a moment in time.

### Step 3: Run Style Survey

Inject and execute `scripts/style-survey.js` on the current page.
Record the JSON output. This provides quantitative evidence for:
- D-1 (font sizes), D-2 (font weights), D-3 (heading hierarchy)
- K-1 (border-radius count), K-2 (color palette), K-3 (spacing)
- A-5 (unlabelled form controls)
- T-1 (table header/body alignment)

### Step 4: Full-Page Scroll Capture

Scroll the full page from top to bottom, capturing a screenshot at
each viewport-height increment. This catches:
- Content below the fold (entire sections may be invisible)
- Scroll containment issues (S-4)
- Footer/bottom-of-page states
- Lazy-loaded content that only appears on scroll

### Step 5: Safe Dirty-State Probe

If the page contains a form or editable content:
1. Type a single character into a text field (do NOT submit)
2. Attempt to navigate away (click a nav link)
3. Observe: does the app warn about unsaved changes? (R-4)
4. If warned: cancel and restore state
5. If NOT warned: document as potential R-4 finding
6. Clear the typed character to restore original state

### Step 6: Safe Modal/Overlay Probe

If the page has modals, drawers, or overlays:
1. Open the overlay via its trigger
2. Press Escape — does it close? (A-4)
3. If not closed by Escape: click behind/outside — does it close?
4. When closed: does focus return to the trigger element? (A-1)
5. While open: Tab through — is focus trapped inside? (A-1)

### Step 7: Cross-Page Entity Consistency

Pick an entity visible on this page (a project name, user name, status
badge, or count). Navigate to a different page that also shows it.
Verify:
- Same entity displays the same value (no stale data)
- Same entity uses the same visual treatment (K-5, C-5)
- Counts match between summary and detail views

### Step 8: Console Error Check

Check the browser console for:
- JavaScript errors (uncaught exceptions)
- Failed network requests (4xx/5xx)
- React/framework warnings (key errors, deprecated APIs)
- Accessibility warnings from browser tooling

Document any errors as supplementary evidence (not direct rubric
findings unless they manifest as user-visible issues).

### Step 9: Identify the Gold-Standard Page

After reviewing multiple pages, identify which page in the application
best follows the rubric — the one with fewest findings and highest
score. Use it as a reference when suggesting fixes:

"Page X does this correctly; page Y should match."

This anchors fixes to existing patterns rather than external references.

---

## Evidence Discipline

### What counts as evidence

| Evidence type | Strength | Use for |
|---|---|---|
| Computed value (from style-survey.js) | Strong | D and K family checks |
| Accessibility tree node | Strong | A family checks |
| Live interaction result | Strong | R, V, E family checks |
| Screenshot + annotation | Medium | S and C family checks |
| Code inspection (supplementary) | Weak | Confirm patterns only |

### Rules

1. **Screenshot-only findings are provisional.** A screenshot proves
   visual state but not behavior. If a finding depends on behavior
   (focus trap, save confirmation, dirty-state warning), it MUST be
   confirmed by live interaction.
2. **Sev-1 findings require reproduction.** Do not assert a Sev-1
   (blocking/data-loss/misleading) from a single observation. Reproduce
   it at least once.
3. **Browser-extension artifacts are not findings.** If a visual anomaly
   only appears in the screenshot and could be caused by a browser
   extension (ad blocker, dev tools overlay), note it as suspect and
   exclude it from scoring.
4. **Platform chrome is not part of the app.** Browser chrome, OS
   notifications, and system dialogs are not reviewed.

---

## Report Output

After completing all pages, produce a report in `docs/ux-reviews/` with
the naming convention `UXR-{NNN}-{YYYY-MM-DD}.md`.

### Report Structure (fixed order)

1. **Summary** — Pages reviewed, Sev counts (1/2/3), gate PASS/FAIL,
   one-paragraph verdict
2. **Systemic findings** — Issues that appear on multiple pages (table
   format: rubric ID, severity, evidence, fix)
3. **Per-page findings** — One table per page, each with rubric ID,
   severity, evidence, fix, and page score
4. **Prioritized plan** — ship-now (Sev-1 or score < 70) / fix-soon
   (Sev-2 high-freq) / defer (Sev-3 or low-freq Sev-2)
5. **Corrections/Retractions** — MANDATORY section. List any findings
   that were initially asserted but later disproved by live interaction,
   and explain why
6. **Notes** — Checks not verifiable in this mode; candidate design
   tokens discovered; suggestions for the gold-standard page

### Gate Result

- **PASS:** Zero Sev-1 findings AND no page below 70/100
- **FAIL:** Any Sev-1 OR any page below 70/100

---

## Corrections/Retractions — MANDATORY

This section exists because live review can initially misidentify
findings that are later disproved. Common causes:
- A screenshot showed a visual issue caused by browser extensions
- A behavior assumed broken was actually working (tested more carefully)
- An ARIA issue was resolved by a complementary element not initially seen

When a prior finding is disproved:
1. Remove it from the scoring
2. Add it to the Corrections/Retractions section with the reason
3. Recalculate the page score

Never delete history — always show what was initially found and why
it was retracted. This builds review credibility over time.

---

## Cross-references

- `.kiro/steering/ux-console-idiom.md` — the rubric (load before starting)
- `scripts/style-survey.js` — quantitative evidence script (Step 3)
- `.kiro/steering/review-policy.md` — when this review triggers
- `.kiro/steering/ux-pattern-registry.md` — reference patterns for common screens
- `docs/ux-reviews/` — report output directory
