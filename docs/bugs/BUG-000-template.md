# {{BUG_ID}}: {{DESCRIPTION}}

## Metadata

| Field | Value |
|-------|-------|
| **ID** | {{BUG_ID}} |
| **Severity** | {{SEVERITY}} |
| **Status** | {{STATUS}} |
| **Category** | {{CATEGORY}} |
| **File** | `{{FILE}}` |
| **Reported** | {{DATE}} |
| **Fixed** | - |
| **Branch** | `{{BRANCH}}` |
| **Commit** | - |

## Problem

{{DESCRIPTION}}

## Code Context (auto-captured at discovery)

```
{{CONTEXT}}
```

## Root Cause

<!-- Fill in: why did this happen? What was the incorrect assumption? -->

## Solution

<!-- Auto-filled from commit message at resolution. Manual override OK. -->
{{SOLUTION}}

## Diff (auto-captured at commit)

```diff
{{DIFF}}
```

## Impact

<!-- What was affected? Users? Data? Other systems? -->

## Regression Tests

| Test | Type | Status |
|------|------|--------|
| `test_{{BUG_ID_LOWER}}_negative` | Reproduces bug (RED) | [ ] Written |
| `test_{{BUG_ID_LOWER}}_positive` | Confirms fix (GREEN) | [ ] Written |

## Variant Search

- [ ] Searched for same pattern at all call sites
- [ ] Found ___ additional instances
- [ ] All variants fixed in same branch

## Lessons / Pattern

<!-- What should the team learn from this? Is this a recurring class? -->
- **Category:** {{CATEGORY}}
- **Recurrence:** (auto-filled by pattern detection if 2+ in same category)
- **Guardrail candidate:** (auto-filled if 3+ — promote to steering rule?)

## Timeline

| Event | Date | Actor |
|-------|------|-------|
| Discovered | {{DATE}} | Bug Scribe (auto) |
| Fix started | - | - |
| Fix committed | - | - |
| Regression tests | - | - |
| Closed | - | - |
