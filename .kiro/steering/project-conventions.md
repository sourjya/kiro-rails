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
