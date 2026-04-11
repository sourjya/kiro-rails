---
inclusion: always
---

# Project-Specific Conventions

Rules specific to this project's codebase, tools, and architecture.

<!-- CUSTOMIZE: Update this entire file for your project's specifics -->

## Git and Terminal Workflow

Terminal output capture can be unreliable in this environment. Always use the standard git scripts in `scripts/` which pipe output through `tee` to `logs/`.

## Domain Constants Strategy

**Rule: All domain constants live in a dedicated constants directory — never inline in model files.**

- Never define domain constants inline in a model file
- When adding a new feature with constants, create a dedicated constants file

## Testing Execution

- Always stream test output: use `pytest -v --tb=short` with NO pipes (`| tail`, `| head`, `| grep`)
- Both positive AND negative test cases are required

## Code Style

- Use `datetime.now(timezone.utc)` — never `datetime.utcnow()` (deprecated)
- Use parameterized queries for all SQL — never string interpolation
- Separation of concerns: keep services as separate classes

## Architecture Decisions

- ADRs are required before major implementations — store them in `docs/decisions/`

## Environment and Tooling

- Always use the existing virtual environment. Never create a new venv folder.
- Never install packages in the global Python registry.

## Port Registry

<!-- CUSTOMIZE: Update with your project's ports -->
Port allocations are tracked in `~/coding/PORT_REGISTRY.md`. Before adding any new service port, check and update the registry.

This project uses ports: <!-- FILL IN -->

## Command Output Logging — MANDATORY

ALL commands that produce output you need to analyze MUST be logged to files using `tee`.

### Logging Pattern:
```bash
python -m pytest tests/ -v --tb=short 2>&1 | tee logs/test_results.log
```

### Log File Location:
- All command logs: `logs/`

## PostgreSQL Database Conventions — MANDATORY

<!-- CUSTOMIZE: Update database names and ports for your project -->

### Central Instance

Use the central PostgreSQL instance running on the host (Windows). Do NOT spin up Docker-based PostgreSQL containers. Connection is via `localhost` or the WSL host IP.

### Credential Management

- The PG superuser (root) password is stored in `.env` as `PG_ROOT_PASSWORD`
- **NEVER use the root account for application connections** — root is for admin operations only
- **NEVER prompt the user for database passwords** — always read from `.env`

### Database Setup Pattern

At project initialization, use the root account to create:

1. **Application database and user**:
   - Database: `<project_name>` (e.g., `home_management`)
   - User: `<project_name>_app` with a generated password stored in `.env` as `DATABASE_PASSWORD`
   - Grant the app user full privileges on the app database only

2. **Test database and user**:
   - Database: `<project_name>_test` (e.g., `home_management_test`)
   - User: `<project_name>_test` with a generated password stored in `.env` as `TEST_DATABASE_PASSWORD`
   - Grant the test user full privileges on the test database only

### .env Structure

```bash
# PostgreSQL root (admin operations, migrations)
PG_ROOT_PASSWORD=<root_password>
PG_HOST=localhost
PG_PORT=5432

# Application database
DATABASE_URL=postgresql://<project>_app:<app_password>@localhost:5432/<project>
DATABASE_PASSWORD=<app_password>

# Test database
TEST_DATABASE_URL=postgresql://<project>_test:<test_password>@localhost:5432/<project>_test
TEST_DATABASE_PASSWORD=<test_password>
```

### Migration Rules (Alembic)

- Alembic connects using the **root account** for running migrations — it needs DDL privileges
- Configure Alembic's `env.py` to read `PG_ROOT_PASSWORD` and connect as superuser
- Application code connects using the **app user** — limited to DML operations on its own database
- Never run migrations with the app user account

### Rules

1. **One database per project** — no sharing databases across projects
2. **Separate test database** — tests never touch the application database
3. **App user has minimal privileges** — only what the application needs (SELECT, INSERT, UPDATE, DELETE on its tables). No CREATE/DROP in production.
4. **Root for admin only** — schema changes, migrations, user creation, grants
5. **All connection strings in `.env`** — never hardcode host, port, database name, or credentials in source code
6. **Test database is disposable** — tests may truncate/recreate tables freely
