---
name: spec-implement
description: Implement a proposed spec. Reads the spec folder, follows the task checklist, writes code using TDD. Use after spec-propose is complete and approved.
---

# Spec Implement Workflow

Implement a feature that has an approved spec in `.kiro/specs/<feature-name>/`.

## Steps

1. **Read the full spec** — proposal.md, requirements.md, design.md, tasks.md
2. **Confirm readiness** — all artifacts exist and tasks are defined
3. **Implement using TDD** — for each task:
   - RED: Write a failing test
   - GREEN: Write minimal code to pass
   - REFACTOR: Clean up while tests pass
4. **Check off tasks** as completed in tasks.md
5. **Update design.md** if implementation deviates from plan (document WHY)

## Pre-Implementation Checklist

Before writing any code, verify:
- [ ] `proposal.md` exists and is approved (user confirmed)
- [ ] `requirements.md` has testable acceptance criteria
- [ ] `design.md` describes the approach
- [ ] `tasks.md` has atomic, ordered tasks
- [ ] No open questions remain in proposal.md (or they've been answered)

## Implementation Rules

1. **Follow task order** — implement tasks in the sequence defined in tasks.md
2. **One task at a time** — complete and verify each task before starting the next
3. **Mark progress** — update `- [ ]` to `- [x]` in tasks.md after each task passes tests
4. **Stay in scope** — if you discover needed work not in the spec, note it but don't implement it. Add it as a new task or flag it for a follow-up spec.
5. **Test against acceptance criteria** — each requirement's criteria must have a corresponding test
6. **Document deviations** — if the implementation differs from design.md, update design.md with the actual approach and rationale

## Completion

When all tasks are checked off:
1. Run the full test suite
2. Verify all acceptance criteria in requirements.md are met
3. Inform the user the spec is ready for verification (use `spec-verify`)
