---
inclusion: always
---

# Project-Specific Conventions

Rules specific to this project's codebase, tools, and architecture.
For project-specific overrides (tech stack, ports, database, code style), see `user-project-overrides.md`.

## Git and Terminal Workflow

Terminal output capture can be unreliable in this environment. Always use the standard git scripts in `scripts/` which pipe output through `tee` to `logs/`.

## Domain Constants Strategy

**Rule: All domain constants live in a dedicated constants directory - never inline in model files.**

- Never define domain constants inline in a model file
- When adding a new feature with constants, create a dedicated constants file

## Testing Execution

- Always stream test output: use `pytest -v --tb=short` with NO pipes (`| tail`, `| head`, `| grep`)
- Both positive AND negative test cases are required

## Code Style

- Use `datetime.now(timezone.utc)` - never `datetime.utcnow()` (deprecated)
- Use parameterized queries for all SQL - never string interpolation
- Separation of concerns: keep services as separate classes

## Architecture Decisions

- ADRs are required before major implementations - store them in `docs/decisions/`

## Environment and Tooling

- Use the project's virtual environment for all Python work. Never install packages globally.
- Never install packages in the global Python registry.

## Command Output Logging - MANDATORY

ALL commands that produce output you need to analyze MUST be logged to files using `tee`.

### Logging Pattern:
```bash
python -m pytest tests/ -v --tb=short 2>&1 | tee logs/test_results.log
```

### Log File Location:
- All command logs: `logs/`


## Reusable Utility Scripts - MANDATORY

**When the first need arises for any repeated operation, write a parameterized reusable script with logging and error checking. Then use that script going forward. No ad-hoc multi-line shell commands for operations that will be repeated.**

### Rules

1. **First need = script.** The moment you do something manually that could recur (restart a service, run a migration, deploy, seed data, check health), write a script in `scripts/`.
2. **Parameterized.** Scripts accept arguments (service name, environment, etc.) - not hardcoded for one case.
3. **Verbose with logging.** Scripts log what they're doing with timestamps. On failure, they print useful diagnostics.
4. **Error checking.** Scripts use `set -uo pipefail`, check exit codes, and fail loudly.
5. **Reuse.** Once a script exists, always use it. Never rewrite the same logic inline.
6. **Discoverable.** Scripts live in `scripts/` with descriptive names. Add a comment header explaining usage.

### Anti-Patterns (BANNED)

```bash
# WRONG - ad-hoc multi-line restart
fuser -k 8060/tcp 2>/dev/null
sleep 2
cd /path/to/project && nohup .venv/bin/python -m uvicorn ...
echo $! > logs/server.pid
sleep 5
curl -s http://localhost:PORT/health

# CORRECT - one-liner using the script
bash scripts/restart-service.sh service-name
```

**Minimize shell calls.** If you find yourself making the same type of shell call 3+ times in a session (restart, health check, token fetch, DB query pattern), that is a candidate for a reusable script. Write it in `scripts/`, then use it going forward. TracePulse `get_audit_trail` can help identify repeated patterns.
