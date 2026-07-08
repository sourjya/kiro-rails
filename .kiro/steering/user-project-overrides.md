---
inclusion: always
---

# Project Overrides

Project-specific values that override the generic defaults in the managed steering files.
This is the ONLY steering file you should edit. All other steering files are managed by
kiro-rails and will be overwritten on upgrade.

<!-- ──────────────────────────────────────────────
     INSTRUCTIONS:
     - Uncomment and fill in sections relevant to your project
     - Delete sections you don't need
     - The installer can populate these values interactively
     ────────────────────────────────────────────── -->

## Tech Stack

<!-- Uncomment and set your stack:
- **Backend**: Python 3.12+ with FastAPI
- **Frontend**: TypeScript with React + Vite
- **Backend Dependencies**: uv with pyproject.toml
- **Frontend Dependencies**: npm with package.json
-->

## Dev Server Ports

<!-- Uncomment and set your ports:
- Backend: FastAPI + uvicorn on port 8000
- Frontend: Vite dev server on port 5173
-->

## Database Engine

<!-- Uncomment your engine and remove the others:

### PostgreSQL
- Host: localhost, Port: 5432
- Use JSONB over JSON for queryable structured data
- Enable pg_stat_statements for query monitoring

### MySQL
- Host: localhost, Port: 3306
- charset=utf8mb4, collation=utf8mb4_unicode_ci
- Enable strict mode (STRICT_TRANS_TABLES)

### SQLite
- Path: ./data/app.db
- Enable WAL mode for concurrent access
-->

## Migration Tool

<!-- Uncomment your migration tool:
- **Alembic** (SQLAlchemy) - migrations run with admin credentials via env.py
- **Prisma Migrate** - schema.prisma is the source of truth
- **Django Migrations** - manage.py migrate with admin DB URL
- **Knex** - knexfile.js reads from .env
-->

## Project-Specific Rules

<!-- Add any rules specific to your project:
- Example: All API responses must include a `request_id` field
- Example: Feature flags are managed via LaunchDarkly, not .env
- Example: Use Celery for all background tasks
-->

## Domain Constants

<!-- List your project's domain-specific constant categories:
- Example: Order statuses (PENDING, CONFIRMED, SHIPPED, DELIVERED, CANCELLED)
- Example: User roles (ADMIN, MANAGER, MEMBER, VIEWER)
- Example: Subscription tiers (FREE, PRO, ENTERPRISE)
-->

## Code Style Overrides

<!-- Add project-specific code style rules:
- Example: Use datetime.now(timezone.utc) - never datetime.utcnow()
- Example: All service classes must inherit from BaseService
- Example: Use structlog for all logging, not stdlib logging
-->

## Design Tokens (UX Rubric Thresholds)

<!-- These values configure the thresholds in .kiro/steering/ux-console-idiom.md.
     The rubric checks are fixed; these numbers are team-configurable.
     Uncomment and set for your design system:

### Typography (D family)
- Body text size range: 13–14px
- Allowed font weights: 400, 600 (max 2)
- Body line-height range: 1.4–1.6

### Surfaces (S family)
- Content primacy: ≥60% of viewport height for primary content

### Consistency (K family)
- Max distinct border-radius values: 2
- Spacing scale base: 4px increments
- Icon style: outline (not mixed)
- Color palette: [list your token names or hex values]

### Save Model (V family)
- Save pattern: explicit (one of: explicit-button | auto-save | inline-confirm)

### Tables (T family)
- Max unbounded list items before pagination: 50

### Feedback timing
- Save confirmation deadline: 300ms
- Long operation progress threshold: 2s

### Date format
- Consistent date format: YYYY-MM-DD (or your team's choice)
-->

## Environment and Tooling

<!-- Uncomment and set your environment:
- Virtual environment: .venv in project root
- Package manager: uv (Python), npm (frontend)
- Linter: ruff (Python), eslint (frontend)
- Formatter: ruff format (Python), prettier (frontend)
-->
