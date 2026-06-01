---
name: ux-preflight
description: >
  Pre-implementation UX gate. Run before coding any UI feature to validate
  layout decisions, interaction placement, and hierarchy. Produces a
  PROCEED/REVISE/BLOCK decision.
inclusion: manual
---

# UX Preflight Review

Before reviewing, read `docs/decisions/` ADRs and any UX/design documentation if they exist. Use documented UX decisions to calibrate recommendations.

Run this BEFORE writing implementation code for any UI feature or screen modification.

## Input (fill before running)

SCREEN: [What screen or component is being built/modified]
PRIMARY_USER: [Who uses this screen most]
PRIMARY_TASK: [What the user came here to do]
REFERENCE_PATTERN: [Product + screen to compare against, e.g. "Asana task detail"]

---

## Preflight Checklist

Produce answers for ALL 10 points. Do not skip any.

### 1. Primary User Goal
What is the single most important thing the user wants to accomplish on this screen?

### 2. Most Common Action
What will the user do most frequently? This action must have the lowest friction.

### 3. Information Hierarchy
Rank the top 5 elements by importance. The visual weight must match this ranking.

### 4. Control Placement Rationale
For every interactive control, state: what does it act on, and how far is it from that object? Flag any control that is more than 200px from its target.

### 5. Pointer Travel Risk
Identify any interaction that requires the user to move across the full screen width. Each such interaction is a friction point.

### 6. Density Assessment
Is this a data-dense screen (grid, table, list) or a content-focused screen (detail, form, reading)? Apply the matching density rule from UX Non-Negotiables.

### 7. Reference Pattern Comparison
Compare against the stated reference pattern:
- Is primary content equally or more readable? 
- Are actions closer or farther from their target?
- Is whitespace similar or better?
- Is interaction cost lower, equal, or higher?

### 8. Required States
List all states this screen must handle: default, empty, loading, error, permission-restricted, success. Flag any missing from the current plan.

### 9. UX Risks
List specific risks this implementation introduces. Examples: "section menu pushed to far-right increases pointer travel", "description area compressed below metadata".

### 10. Decision

Output ONE of:
- **PROCEED** - no UX risks identified, implementation can begin
- **REVISE** - minor issues found, list required corrections, then proceed
- **BLOCK** - significant UX violations, must redesign before coding

---

## Output Format

```
SCREEN: [name]
DECISION: [PROCEED / REVISE / BLOCK]

Hierarchy: [ranked list]
Risks: [list or "none"]
Required corrections: [list or "none"]
Reference comparison: [better / equal / worse on each dimension]
```
