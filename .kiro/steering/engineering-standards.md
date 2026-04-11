---
inclusion: always
---

# Engineering Execution Standards

This project follows strict engineering standards. All code contributions must adhere to these rules.

## Runtime and Environment

<!-- CUSTOMIZE: Update for your project's tech stack -->
- **Backend**: Python 3.12+ with FastAPI
- **Frontend**: TypeScript with React + Vite
- **Backend Dependencies**: uv with pyproject.toml
- **Frontend Dependencies**: npm with package.json

## Code Organization

<!-- CUSTOMIZE: Update directory structures for your project -->

### Backend Structure
```
backend/
├── src/
│   ├── api/           # FastAPI routes and endpoints
│   ├── core/          # Configuration, security, database
│   ├── common/        # Shared utilities, middleware, logging
│   ├── models/        # SQLAlchemy models
│   ├── schemas/       # Pydantic schemas
│   └── main.py        # Application entry point
└── tests/             # Test suite
```

### Frontend Structure
```
frontend/
├── src/
│   ├── app/           # Application root
│   ├── features/      # Feature-sliced modules
│   ├── shared/        # Shared components, hooks, utils
│   ├── services/      # API clients
│   └── types/         # TypeScript type definitions
└── tests/             # Test suite
```

## Test File Locations — STRICT

- **NEVER** create `__tests__/` folders, co-located test files, or any alternative test directory structure
- **Frontend tests** go in the project's designated test directory
- **Backend tests** go in `backend/tests/` only
- Place new test files in the subdirectory matching the domain of the code under test

## Task-First Discipline — MANDATORY

**CRITICAL**: No code may be written without a task list. This is non-negotiable.

**Where the task list lives:**
- Full spec features: `.kiro/specs/{feature-name}/tasks.md`
- Bug fixes: `docs/bugs/BUG-###-description.md`
- Minor enhancements: create a minimal task list inline before starting

**The task list must be followed in order:**
1. Read the full task list before writing any code
2. Mark each task `[-]` (in progress) before starting it
3. Write tests FIRST (RED phase) per TDD rules
4. Implement to make tests pass (GREEN phase)
5. Mark each task `[x]` (complete) before moving to the next
6. Never skip tasks or reorder them without documenting why

## Test-Driven Development (TDD) — MANDATORY

### The TDD Cycle

1. **RED**: Write a failing test first
2. **GREEN**: Write minimal code to make it pass
3. **REFACTOR**: Clean up while keeping tests green

### TDD Workflow Rules

- **NEVER write implementation code before writing its test**
- **NEVER skip the RED phase** — you must see the test fail first
- **Tests define the contract** — implementation fulfills it
- Each test should fail for the right reason (missing functionality, not syntax errors)

### Exceptions to TDD

The ONLY exceptions where you may write code before tests:
- Database migrations (but test the models they create)
- Configuration files (JSON, YAML, .env templates)
- Documentation (Markdown, ADRs)
- Build scripts and tooling configuration

### Testing Requirements

- Every bug fix must include a regression test
- Minimum 80% code coverage for new code
- Both positive AND negative test cases required for every feature

## Documentation Requirements

- All modules, classes, and functions must have docstrings/JSDoc
- Comments explain intent, tradeoffs, and "why" — not syntax or "what"
- Changelog updated before every meaningful commit
- All docs live in docs/ directory (except README.md)

## Security Requirements

- No credentials in source control
- Use .env.example for configuration templates
- Run secret-exposure review before commits

## Local Development Servers

<!-- CUSTOMIZE: Update ports for your project. Check ~/coding/PORT_REGISTRY.md -->
- Backend: FastAPI + uvicorn on port XXXX
- Frontend: Vite dev server on port XXXX

## Commit Discipline

- Commit at meaningful milestones
- Descriptive commit messages stating what and why
- Update changelog for behavior/structure changes
- Verify tests pass before committing

## Changelog Rolling Policy

- `docs/changelogs/CHANGELOG.md` should stay under **500 lines**
- When it exceeds 500 lines, roll over: rename to `docs/changelogs/CHANGELOG.YYYY-MM-DD.md` and start fresh
- Do NOT copy, summarize, or selectively preserve entries — just roll it over clean
- Write **consolidated** changelog entries grouped by feature
