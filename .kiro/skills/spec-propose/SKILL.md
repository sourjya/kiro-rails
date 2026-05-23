---
name: spec-propose
description: Propose a new feature or change. Creates a structured spec folder with proposal, requirements, design, and tasks before any code is written. Use when starting new work.
---

# Spec Propose Workflow

When the user wants to propose a new feature or change, create a structured spec folder BEFORE writing any code.

## Steps

1. **Ask clarifying questions** — understand scope, constraints, affected areas
2. **Create the spec folder** at `.kiro/specs/<feature-name>/`
3. **Generate all artifacts** in order:

## Folder Structure

```
.kiro/specs/<feature-name>/
├── proposal.md      # Why this change exists
├── requirements.md  # What the system should do
├── design.md        # How to implement it
└── tasks.md         # Checkbox-tracked implementation steps
```

## proposal.md Template

```markdown
# Proposal: <Feature Name>

## Problem Statement
What problem does this solve? Who is affected?

## Proposed Solution
High-level description of the approach.

## Scope
- **In scope:** what this change includes
- **Out of scope:** what this change explicitly excludes

## Success Criteria
How do we know this is done and working?

## Risks & Open Questions
- Risk 1: ...
- Question 1: ...
```

## requirements.md Template

```markdown
# Requirements: <Feature Name>

## Functional Requirements

### REQ-1: <Requirement Name>
**Description:** What the system must do.
**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2

### REQ-2: <Requirement Name>
...

## Non-Functional Requirements
- Performance: ...
- Security: ...
- Accessibility: ...
```

## design.md Template

```markdown
# Design: <Feature Name>

## Architecture
How this fits into the existing system.

## Key Decisions
| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|
| ... | ... | ... |

## Data Model Changes
Describe any schema/model changes.

## API Changes
Describe any endpoint additions/modifications.

## Dependencies
What this depends on, what depends on this.
```

## tasks.md Template

Use the TDD template from `.kiro/templates/tasks-template-tdd.md` if available. Otherwise:

```markdown
# Tasks: <Feature Name>

## Implementation Checklist

- [ ] Task 1: ...
- [ ] Task 2: ...
- [ ] Task 3: ...

## Testing
- [ ] Unit tests for ...
- [ ] Integration tests for ...

## Documentation
- [ ] Update relevant docs
- [ ] Add ADR if architectural decision was made
```

## Rules

1. **Never skip the proposal** — even for "small" changes, write at minimum a 3-sentence proposal
2. **Requirements must be testable** — every requirement needs acceptance criteria
3. **Design must reference requirements** — trace each design decision to a requirement
4. **Tasks must be atomic** — each task should be completable in one session
5. **Get user confirmation** on the proposal before proceeding to requirements
