---
inclusion: always
---

# Chokepoint Logging — MANDATORY

A chokepoint is any error, crash, or near-miss that required multiple attempts to fix or revealed a gap in process. Logging them creates institutional memory that prevents the same class of bug from recurring.

## What Is a Chokepoint

Any error that:
- Required more than one attempt to fix
- Was caused by a pattern that could recur elsewhere
- Revealed a gap in tooling, testing, or process
- Broke production (even briefly)

## When to Log

**On attempt #2+ of any fix.** Do NOT wait until the fix is done.

1. **BEFORE fixing** (on attempt #2+): Append to `docs/engineering/chokepoint-log.md`:
   ```
   ### CP-NNN: description | file | attempt #N | gap: what was missing
   ```
2. **AFTER green** (before next task): Append resolution:
   ```
   - **Root cause:** one sentence
   - **Resolution:** one sentence
   - **Pattern:** category tag
   - **Guardrail candidate:** proposed rule or test
   ```

## Pattern Categories

| Tag | Meaning |
|-----|---------|
| ROUTE_ORDERING | Specific routes must precede parameterized catch-alls |
| CSS_OVERSIGHT | Missing scrollbar/overflow/responsive handling |
| LAYOUT_OVERFLOW | Flex/grid children exceeding viewport |
| QUERY_INVALIDATION | Mutation not invalidating all affected queries |
| TYPE_MISMATCH | API returns different shape than frontend expects |
| IMPORT_ERROR | Wrong export/import pattern causing runtime crash |
| DEPLOY_REGRESSION | Build deployed without smoke test |
| TOOL_MISUSE | Using wrong tool when a dedicated tool exists |
| STATE_SYNC | Multiple sources of truth drifting apart |
| RACE_CONDITION | Async operations executing in wrong order |

Add new categories as they emerge.

## Periodic Analysis

At the end of each sprint (or every 20 chokepoints), review the log for:
1. **Recurring patterns** — promote to steering rules
2. **Tooling gaps** — file as feature requests or create scripts
3. **Test gaps** — add regression tests or smoke tests
4. **Process gaps** — update documentation or checklists

## Guardrail Promotion

When a pattern appears 3+ times:
1. Write a concrete steering rule in the appropriate steering file
2. Add a regression test if applicable
3. Mark the chokepoint entries as "promoted" with a link to the rule
4. Consider automation (hooks, linters, CI checks)
