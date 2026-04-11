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

### Folder Organization Principles — MANDATORY

These rules apply regardless of framework, language, or stack.

#### Backend: Domain-Grouped Within Layers

Organize backend code by **layer first, domain second**. Each layer directory (routes, models, schemas, services) contains subdirectories grouped by domain when the project has more than a handful of files per layer.

```
backend/src/
├── api/                      # Route/controller layer
│   ├── v1/                   # API version namespace
│   │   ├── auth.py
│   │   ├── users.py
│   │   └── products.py
│   └── deps.py               # Shared route dependencies (auth, db session)
├── core/                     # Configuration, security, database setup
├── common/                   # Cross-cutting: middleware, logging, shared utils
├── models/                   # ORM / data models
│   ├── auth/                 # user.py, role.py, session.py
│   ├── products/             # product.py, category.py
│   └── base.py               # Shared base model
├── schemas/                  # Request/response schemas (Pydantic, Zod, etc.)
│   ├── auth/
│   ├── products/
│   └── common.py             # Shared pagination, error response schemas
├── services/                 # Business logic layer
│   ├── auth/
│   ├── products/
│   └── base.py               # Base service class if applicable
├── constants/                # Domain constants — NEVER inline in model files
│   ├── auth.py
│   └── products.py
└── main.py                   # Application entry point
```

**Rules:**
- Group by domain when a layer has 5+ files. Below that, flat is fine.
- Each domain subdirectory gets an `__init__.py` (Python) or `index.ts` (TS) that re-exports its public API.
- `common/` is for truly cross-cutting concerns (logging, middleware, error handling). Not a dumping ground.
- `constants/` holds all domain constants — never define them inline in model or service files.
- Adapt layer names to your framework's conventions (e.g., `views/` for Django, `handlers/` for Go, `controllers/` for Express).

#### Frontend: Feature-Sliced Design

Organize frontend code by **feature first**. Each feature is a self-contained module with its own components, hooks, services, and types.

```
frontend/src/
├── app/                      # Application root (routing, providers, layout)
├── features/                 # Feature modules — one per domain
│   ├── auth/
│   │   ├── components/       # Feature-specific UI components
│   │   ├── hooks/            # Feature-specific hooks
│   │   ├── services/         # API calls for this feature
│   │   ├── types/            # Feature-specific type definitions
│   │   ├── utils/            # Feature-specific helpers
│   │   └── index.ts          # Public API — ONLY export what other features need
│   ├── dashboard/
│   │   ├── components/
│   │   ├── hooks/
│   │   └── index.ts
├── shared/                   # Cross-feature reusable code
│   ├── components/           # Generic UI (Button, Modal, Layout)
│   ├── hooks/                # Generic hooks (useDebounce, useLocalStorage)
│   ├── utils/                # Generic helpers (formatDate, cn())
│   └── types/                # Shared type definitions
├── services/                 # Global API client setup, interceptors
└── types/                    # App-wide type definitions
```

**Rules:**
- Features never import from each other's internals — only through `index.ts`.
- If feature A needs something from feature B, it goes through B's public `index.ts` export, or it belongs in `shared/`.
- Each feature's `index.ts` is the only entry point. Internal files are private to the feature.
- This pattern works for React, Vue, Svelte, Angular, or any component-based framework.

#### Shared vs Feature-Scoped — Graduation Policy

Code starts in the feature where it was first needed and graduates to `shared/` only when reuse is proven:

1. **First use**: lives inside the feature directory
2. **Second feature needs it**: move it to `shared/` and update both imports
3. **Never preemptively put code in `shared/`** — that creates a junk drawer
4. `shared/` items must be genuinely generic: no feature-specific logic, no domain assumptions, no hardcoded business rules
5. If a "shared" item accumulates feature-specific parameters or branches, it should be split back into feature-scoped copies

#### Customizing for Your Stack

The directory structures above are defaults. Adapt them to your stack:

- **Backend-only project**: remove the frontend section entirely — don't leave dead structure
- **Frontend-only project**: remove the backend section entirely
- **Different framework**: rename layers to match your framework's conventions (e.g., Django `views/`, Go `handlers/`, Rails `controllers/`)
- **Monorepo**: use `packages/` with each package following the same internal layer/feature structure
- **No ORM**: replace `models/` with whatever your data layer uses (`entities/`, `repositories/`, etc.)
- Keep the principles (layer-first backend, feature-first frontend, graduation policy) even when the directory names change

## Reusable Component Architecture — MANDATORY

Before building any new service, module, component, or helper, think reuse-first.

### Design-Time Mindset

1. **Search before building** — scan the codebase for existing implementations that solve the same or a similar problem. Duplication is a bug.
2. **Identify the generic core** — every piece of logic has a domain-specific shell and a generic core. Extract the generic core as a standalone unit with clean inputs/outputs.
3. **Design for reuse, place locally** — architect components with clean interfaces, dependency injection, and no hardcoded assumptions. But place them in the feature where they're first needed (per the Graduation Policy). The clean design makes future graduation to `shared/` trivial.
4. **Pure functions by default** — helper methods and utilities should be pure functions (no side effects, no hidden state, no implicit dependencies) wherever possible. Pure functions are trivially reusable and testable.
5. **Parameterize, don't specialize** — if a component could serve multiple consumers with minor variations, accept those variations as parameters rather than forking the implementation.

### When NOT to Make Something Reusable

- If it requires more than 3 domain-specific parameters to generalize, it's not ready — keep it feature-scoped
- If the "generic" version would be more complex than two specialized copies, don't abstract
- If only one consumer exists and no second consumer is foreseeable, don't over-engineer

### Review Checkpoint

When designing any new module, answer these before writing code:
- Does something similar already exist in the codebase?
- What is the generic core vs. the domain-specific wrapper?
- Could another feature, service, or project use this with zero modification?
- Am I hardcoding anything that should be a parameter?

## Centralized Configuration & Constants — MANDATORY

**ZERO embedded literals.** All configuration values, magic numbers, string constants, and environment-dependent settings must live in dedicated, centralized locations — never scattered across modules.

### Configuration Hierarchy

```
backend/src/
├── core/
│   └── config.py             # App config: reads from env vars, .env, defaults
├── constants/                # Domain constants — organized by domain
│   ├── auth.py               # Roles, token lifetimes, OAuth scopes
│   ├── products.py           # Categories, statuses, limits
│   └── common.py             # Shared constants (pagination defaults, date formats)
```

```
frontend/src/
├── shared/
│   └── config/
│       ├── env.ts            # Environment-dependent config (API URLs, feature flags)
│       └── constants.ts      # App-wide constants
├── features/
│   └── auth/
│       └── constants.ts      # Feature-scoped constants (only if used by this feature alone)
```

### Rules

1. **No string literals in business logic** — URLs, status values, error messages, field names, limits, thresholds — all go in constants files or config.
2. **No magic numbers** — every numeric value with business meaning gets a named constant with a comment explaining why that value was chosen.
3. **Config reads from environment** — all environment-dependent values (DB URLs, API keys, feature flags, ports) go through a single config module that reads from `.env` / environment variables with typed defaults.
4. **Constants are grouped by domain** — `constants/auth.py` for auth-related values, `constants/products.py` for product-related values. Not one giant constants file.
5. **Feature-scoped constants stay in the feature** — if a constant is only used within one feature, it lives in that feature's `constants.ts` or at the top of the relevant module. It graduates to `shared/` or `constants/` when a second consumer appears.
6. **Enums over string literals** — use enums (Python `Enum`, TypeScript `enum` or `as const`) for any value that has a fixed set of options. Never compare against raw strings.
7. **Single source of truth** — if the same value is needed by both frontend and backend, define it in the backend and expose it via API or shared schema. Never duplicate constants across the stack.

### What Belongs Where

| Value type | Location |
|---|---|
| Environment-dependent (DB URL, API keys, ports) | `core/config.py` / `shared/config/env.ts` |
| Domain constants (statuses, roles, categories) | `constants/<domain>.py` / `features/<domain>/constants.ts` |
| Shared constants (pagination, date formats) | `constants/common.py` / `shared/config/constants.ts` |
| Error messages | `constants/<domain>.py` or a dedicated `constants/errors.py` |
| Feature flags | `core/config.py` (read from env) |

## Test Folder Organization — STRICT

### Directory Structure

```
tests/
├── unit/                     # Fast, isolated tests — no I/O, no DB, no network
│   ├── auth/                 # Mirrors backend/src domain structure
│   │   ├── test_auth_service.py
│   │   └── test_token_utils.py
│   ├── products/
│   │   ├── test_product_service.py
│   │   └── test_pricing.py
│   └── common/
│       └── test_pagination.py
├── integration/              # Tests that hit real DB, APIs, or external services
│   ├── test_auth_flow.py
│   └── test_product_api.py
├── e2e/                      # End-to-end tests (Playwright, Cypress, etc.)
│   └── test_checkout_flow.py
├── property/                 # Property-based tests (Hypothesis, fast-check)
│   └── test_pricing_properties.py
├── conftest.py               # Root fixtures: DB sessions, auth helpers, test client
└── unit/conftest.py          # Unit-specific fixtures (mocks, fakes)
```

### Rules

- **NEVER** create `__tests__/` folders, co-located test files, or any alternative test directory structure
- **Unit test subdirectories mirror source domains** — if the source has `services/auth/`, tests go in `tests/unit/auth/`
- **One test file per source file** — `auth_service.py` → `test_auth_service.py`. Never bundle unrelated tests.
- **Test file naming mirrors source** — prefix with `test_` (Python) or suffix with `.test.ts` / `.spec.ts` (TypeScript)
- **Shared fixtures in conftest.py** — never duplicate fixture setup across test files. Extract to the nearest `conftest.py`.
- **Integration tests are separate from unit tests** — unit tests must run without any external dependencies (DB, network, filesystem). Integration tests get their own directory.
- **Create subdirectories as domains emerge** — don't pre-create empty test directories. Add them when the first test for that domain is written.

### Frontend Test Structure

```
frontend/tests/
├── unit/
│   ├── auth/
│   │   ├── LoginForm.test.tsx
│   │   └── useAuth.test.ts
│   ├── dashboard/
│   │   └── DashboardPage.test.tsx
│   └── shared/
│       └── Button.test.tsx
├── integration/
│   └── auth-flow.test.ts
├── e2e/
│   └── checkout.spec.ts
└── setup.ts                  # Test setup (mocks, providers, global config)
```

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
