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

### Folder Organization Principles - MANDATORY

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
├── constants/                # Domain constants - NEVER inline in model files
│   ├── auth.py
│   └── products.py
└── main.py                   # Application entry point
```

**Rules:**
- Group by domain when a layer has 5+ files. Below that, flat is fine.
- Each domain subdirectory gets an `__init__.py` (Python) or `index.ts` (TS) that re-exports its public API.
- `common/` is for truly cross-cutting concerns (logging, middleware, error handling). Not a dumping ground.
- `constants/` holds all domain constants - never define them inline in model or service files.
- Adapt layer names to your framework's conventions (e.g., `views/` for Django, `handlers/` for Go, `controllers/` for Express).

#### Frontend: Feature-Sliced Design

Organize frontend code by **feature first**. Each feature is a self-contained module with its own components, hooks, services, and types.

```
frontend/src/
├── app/                      # Application root (routing, providers, layout)
├── features/                 # Feature modules - one per domain
│   ├── auth/
│   │   ├── components/       # Feature-specific UI components
│   │   ├── hooks/            # Feature-specific hooks
│   │   ├── services/         # API calls for this feature
│   │   ├── types/            # Feature-specific type definitions
│   │   ├── utils/            # Feature-specific helpers
│   │   └── index.ts          # Public API - ONLY export what other features need
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
- Features never import from each other's internals - only through `index.ts`.
- If feature A needs something from feature B, it goes through B's public `index.ts` export, or it belongs in `shared/`.
- Each feature's `index.ts` is the only entry point. Internal files are private to the feature.
- This pattern works for React, Vue, Svelte, Angular, or any component-based framework.

#### Shared vs Feature-Scoped - Graduation Policy

Code starts in the feature where it was first needed and graduates to `shared/` only when reuse is proven:

1. **First use**: lives inside the feature directory
2. **Second feature needs it**: move it to `shared/` and update both imports
3. **Never preemptively put code in `shared/`** - that creates a junk drawer
4. `shared/` items must be genuinely generic: no feature-specific logic, no domain assumptions, no hardcoded business rules
5. If a "shared" item accumulates feature-specific parameters or branches, it should be split back into feature-scoped copies

#### Customizing for Your Stack

The directory structures above are defaults. Adapt them to your stack:

- **Backend-only project**: remove the frontend section entirely - don't leave dead structure
- **Frontend-only project**: remove the backend section entirely
- **Different framework**: rename layers to match your framework's conventions (e.g., Django `views/`, Go `handlers/`, Rails `controllers/`)
- **Monorepo**: use `packages/` with each package following the same internal layer/feature structure
- **No ORM**: replace `models/` with whatever your data layer uses (`entities/`, `repositories/`, etc.)
- Keep the principles (layer-first backend, feature-first frontend, graduation policy) even when the directory names change

## Reusable Component Architecture - MANDATORY

Before building any new service, module, component, or helper, think reuse-first.

### Design-Time Mindset

1. **Search before building** - scan the codebase for existing implementations that solve the same or a similar problem. Duplication is a bug.
2. **Identify the generic core** - every piece of logic has a domain-specific shell and a generic core. Extract the generic core as a standalone unit with clean inputs/outputs.
3. **Design for reuse, place locally** - architect components with clean interfaces, dependency injection, and no hardcoded assumptions. But place them in the feature where they're first needed (per the Graduation Policy). The clean design makes future graduation to `shared/` trivial.
4. **Pure functions by default** - helper methods and utilities should be pure functions (no side effects, no hidden state, no implicit dependencies) wherever possible. Pure functions are trivially reusable and testable.
5. **Parameterize, don't specialize** - if a component could serve multiple consumers with minor variations, accept those variations as parameters rather than forking the implementation.

### When NOT to Make Something Reusable

- If it requires more than 3 domain-specific parameters to generalize, it's not ready - keep it feature-scoped
- If the "generic" version would be more complex than two specialized copies, don't abstract
- If only one consumer exists and no second consumer is foreseeable, don't over-engineer

### Review Checkpoint

When designing any new module, answer these before writing code:
- Does something similar already exist in the codebase?
- What is the generic core vs. the domain-specific wrapper?
- Could another feature, service, or project use this with zero modification?
- Am I hardcoding anything that should be a parameter?

## Infrastructure Abstraction - MANDATORY

**Every external dependency gets an interface.** Storage, email, payments, auth providers, AI models, notification channels - all must be accessed through an abstract interface with swappable backend implementations. No service should be hardwired to a specific vendor or infrastructure.

### Adapter Pattern for External Services

Define an abstract interface for each infrastructure concern. Implement one adapter per backend. Application code depends only on the interface, never on a concrete implementation.

This applies to:
- **File storage** (local filesystem ↔ S3 ↔ GCS)
- **Configuration persistence** (file ↔ localStorage ↔ IndexedDB)
- **Email/SMS** (console logger ↔ SES ↔ SendGrid)
- **Notifications** (log ↔ SNS ↔ WebSocket)
- **AI/ML providers** (local model ↔ OpenAI ↔ Bedrock)
- **Payment processing**, **auth providers**, and any other external service

### Factory + Config-Driven Instantiation

Backends are selected via configuration, never hardcoded. A factory function reads the config and returns the correct adapter:

```python
storage = create_storage_backend(settings.STORAGE_BACKEND)  # "local" | "s3"
email = create_email_backend(settings.EMAIL_BACKEND)         # "console" | "ses"
```

- The factory is the only place that knows about concrete implementations
- Application code receives the interface - it never imports a specific backend directly
- Switching providers is a config change, not a code change

### Secure Defaults

All infrastructure adapters must enforce security at the interface level:

1. **Content-type validation** - never trust client-provided MIME types on upload. Validate server-side.
2. **Size limits at the interface** - enforce max file size in the abstract interface, not just the implementation. Every backend inherits the same limits.
3. **Path traversal prevention** - sanitize all keys and paths. Reject `../`, absolute paths, and null bytes.
4. **Signed/expiring URLs** - never expose raw storage paths (S3 keys, file paths). All download URLs must be signed with expiration.
5. **Least privilege** - each adapter uses credentials scoped to its specific function. Storage adapters don't get database credentials.

### Idempotency

- **Uploads** are idempotent - uploading the same key with the same content is a no-op
- **Deletes** are idempotent - deleting a non-existent object succeeds silently
- **Config writes** are idempotent - writing the same value is a no-op
- Design all infrastructure operations so they can be safely retried without side effects

### Observability

Every infrastructure adapter must emit structured logs for every operation:
- **What**: operation type (upload, download, delete, send)
- **Target**: key, recipient, resource identifier
- **Size**: bytes transferred (where applicable)
- **Duration**: wall-clock time of the operation
- **Outcome**: success or failure with error category
- The abstract interface defines the logging contract - implementations inherit it, not duplicate it

## Centralized Configuration & Constants - MANDATORY

**ZERO embedded literals.** All configuration values, magic numbers, string constants, and environment-dependent settings must live in dedicated, centralized locations - never scattered across modules.

### Configuration Hierarchy

```
backend/src/
├── core/
│   └── config.py             # App config: reads from env vars, .env, defaults
├── constants/                # Domain constants - organized by domain
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

1. **No string literals in business logic** - URLs, status values, error messages, field names, limits, thresholds - all go in constants files or config.
2. **No magic numbers** - every numeric value with business meaning gets a named constant with a comment explaining why that value was chosen.
3. **Config reads from environment** - all environment-dependent values (DB URLs, API keys, feature flags, ports) go through a single config module that reads from `.env` / environment variables with typed defaults.
4. **Constants are grouped by domain** - `constants/auth.py` for auth-related values, `constants/products.py` for product-related values. Not one giant constants file.
5. **Feature-scoped constants stay in the feature** - if a constant is only used within one feature, it lives in that feature's `constants.ts` or at the top of the relevant module. It graduates to `shared/` or `constants/` when a second consumer appears.
6. **Enums over string literals** - use enums (Python `Enum`, TypeScript `enum` or `as const`) for any value that has a fixed set of options. Never compare against raw strings.
7. **Single source of truth** - if the same value is needed by both frontend and backend, define it in the backend and expose it via API or shared schema. Never duplicate constants across the stack.

### What Belongs Where

| Value type | Location |
|---|---|
| Environment-dependent (DB URL, API keys, ports) | `core/config.py` / `shared/config/env.ts` |
| Domain constants (statuses, roles, categories) | `constants/<domain>.py` / `features/<domain>/constants.ts` |
| Shared constants (pagination, date formats) | `constants/common.py` / `shared/config/constants.ts` |
| Error messages | `constants/<domain>.py` or a dedicated `constants/errors.py` |
| Feature flags | `core/config.py` (read from env) |

## Test Folder Organization - STRICT

### Directory Structure

```
tests/
├── unit/                     # Fast, isolated tests - no I/O, no DB, no network
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
- **Unit test subdirectories mirror source domains** - if the source has `services/auth/`, tests go in `tests/unit/auth/`
- **One test file per source file** - `auth_service.py` → `test_auth_service.py`. Never bundle unrelated tests.
- **Test file naming mirrors source** - prefix with `test_` (Python) or suffix with `.test.ts` / `.spec.ts` (TypeScript)
- **Shared fixtures in conftest.py** - never duplicate fixture setup across test files. Extract to the nearest `conftest.py`.
- **Integration tests are separate from unit tests** - unit tests must run without any external dependencies (DB, network, filesystem). Integration tests get their own directory.
- **Create subdirectories as domains emerge** - don't pre-create empty test directories. Add them when the first test for that domain is written.

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

## Task-First Discipline - MANDATORY

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

## Test-Driven Development (TDD) - MANDATORY

### The TDD Cycle

1. **RED**: Write a failing test first
2. **GREEN**: Write minimal code to make it pass
3. **REFACTOR**: Clean up while keeping tests green

### TDD Workflow Rules

- **NEVER write implementation code before writing its test**
- **NEVER skip the RED phase** - you must see the test fail first
- **Tests define the contract** - implementation fulfills it
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

- See `code-commenting-standards.md` for docstring and comment rules
- Changelog updated before every meaningful commit
- All docs live in docs/ directory (except README.md)

## Security Requirements

- No credentials in source control
- Use .env.example for configuration templates
- Run secret-exposure review before commits

## Themed Dialogs - MANDATORY

**All confirmation dialogs, alerts, and informational popups must use the application's themed dialog components. No exceptions.**

### Rules

1. **Never use native browser dialogs** - `window.alert()`, `window.confirm()`, and `window.prompt()` are forbidden. They cannot be styled, break the visual experience, and behave inconsistently across browsers.
2. **Use the application's dialog/modal system** - every dialog must render through the project's themed component (e.g., `ConfirmDialog`, `AlertDialog`, `Modal`) so it inherits the design system's colors, typography, spacing, and animations.
3. **Consistent UX across all interactions** - destructive actions get a themed confirmation dialog with clear action labels (not "OK/Cancel"). Informational messages use themed toast/snackbar notifications. Error messages use themed error dialogs with context.
4. **Accessible by default** - themed dialogs must trap focus, support Escape to close, and include proper ARIA roles (`role="dialog"`, `aria-modal="true"`).

## Error Handling Standards - MANDATORY

**Errors must be explicit, contextual, and never silently swallowed.**

### Rules

1. **Never silently ignore errors** - every error must be raised, logged, or explicitly handled. Empty `except:` / `catch {}` blocks are forbidden.
2. **Use specific error types** - not catch-all handlers. Each error type should clearly indicate what went wrong and where.
3. **Error messages must include context** - request parameters, status codes, what operation was being attempted, and what input caused the failure. No generic "something went wrong."
4. **No automatic fallbacks** - code should either succeed or fail clearly. Fallbacks are only allowed when explicitly designed and documented. Silent fallbacks hide real problems.
5. **Fix root causes, not symptoms** - if an error keeps occurring, fix the underlying issue rather than adding retry/fallback logic around it.
6. **External service calls: retry with backoff** - use exponential backoff for transient failures. Raise the last error if all attempts fail. Log each retry attempt.
7. **API endpoints return proper HTTP status codes** - never return 200 for errors. Use 4xx for client errors, 5xx for server errors, with structured error response bodies.
8. **Frontend errors: catch at boundaries** - use error boundaries (React) or equivalent. Show user-friendly messages, log the full error for debugging.

## Performance Guidelines - MANDATORY

**Design for efficiency from the start. Performance is not an afterthought.**

### Rules

1. **Cache expensive operations** - database queries, API calls, computed values. Use appropriate cache invalidation strategies.
2. **Pagination for all list endpoints** - never return unbounded result sets. Default page size must be a named constant.
3. **No N+1 queries** - use eager loading, joins, or batch queries. Review ORM-generated SQL for new endpoints.
4. **Lazy load heavy resources** - large images, optional modules, below-the-fold content. Load on demand, not upfront.
5. **Database indexes** - every column used in WHERE, JOIN, or ORDER BY clauses in frequent queries must have an index. Document index decisions.
6. **Bundle size awareness (frontend)** - monitor bundle size. Use code splitting and tree shaking. Avoid importing entire libraries when only one function is needed.
7. **Timeouts on all external calls** - every HTTP request, database query, and external service call must have an explicit timeout. No indefinite waits.

## Permission Boundaries - MANDATORY

**Explicit rules for what may be changed, what requires approval, and what must never be touched.**

### ✅ Always Allowed
- Read any file in the repository
- Run linting, type checking, and tests
- Edit source files within the scope of the current task
- Update documentation and changelog

### ⚠️ Ask First
- Adding or removing dependencies
- Database schema changes or new migrations
- Deleting files or directories
- Changing CI/CD configuration
- Modifying shared infrastructure code used by multiple services

### 🚫 Never
- Commit secrets, `.env` files, or credentials
- Force push to `main` or protected branches
- Modify generated files (`dist/`, `build/`, lock files unless updating deps)
- Modify already-applied database migrations
- Remove or weaken existing tests (unless explicitly asked)
- Change code outside the scope of the current task

## Consistency - Match Existing Patterns - MANDATORY

**When touching existing code, matching the existing style is more important than "ideal" style.**

### Rules

1. **New code must look like it was written by the same author** - match naming conventions, formatting, patterns, and idioms already present in the file/module.
2. **Follow existing patterns from similar components** - before creating a new service, route, or component, find an existing one that does something similar and follow its structure.
3. **Don't refactor while implementing** - if you notice code that could be improved but it's outside the current task, note it for later. Don't mix refactoring with feature work.
4. **When in doubt, be consistent** - if the codebase uses one pattern and the style guide says another, follow the codebase. Consistency within a project trumps external standards.

## Change Scope Discipline - MANDATORY

**Change only what was asked for. No drive-by refactors, no unsolicited improvements.**

### Rules

1. **Minimal changes** - modify as few lines as possible while correctly solving the problem. Every changed line must be justified by the task.
2. **No extra improvements** - do not refactor, optimize, or "clean up" code that is not part of the current task, even if it looks wrong.
3. **No unsolicited dependency updates** - don't upgrade packages, change configs, or modify tooling unless the task requires it.
4. **Scope creep is a bug** - if implementation reveals a needed change outside the current scope, document it as a separate task. Don't silently expand the change.
5. **Review your diff before committing** - every line in the diff should relate to the task. If something doesn't, revert it.

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
- Do NOT copy, summarize, or selectively preserve entries - just roll it over clean
- Write **consolidated** changelog entries grouped by feature
