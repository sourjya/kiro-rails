# Project Roadmap

## Current Version

v0.12.0 ([release](https://github.com/sourjya/kiro-rails/releases/tag/v0.12.0))

## Milestones

| Milestone | Target Date | Specs | ADRs | Status |
|-----------|-------------|-------|------|--------|
| M1: Project Setup | YYYY-MM-DD | - | [ADR-001](../decisions/ADR-001-tech-stack.md) | Not Started |
| M2: Core Feature | YYYY-MM-DD | `feat/feature-name` | - | Not Started |

## Security Reviews

| SRR | Date | Scope | Findings | Report |
|-----|------|-------|----------|--------|
| SRR-001 | YYYY-MM-DD | Initial review | - | [Report](../security/SRR-001-YYYY-MM-DD.md) |

## Completed

| Version | Date | Shipped |
|---------|------|---------|
| v0.13.0 | 2026-06-11 | Git commit & PR discipline - merged `git-and-focus-discipline.md`, new `agent-boundaries.md`, defensive-checkpoint + meaningful-checkpoint + session-end commit rules, `commit-checkpoint-on-stop` + `variant-search-on-fix-branch` hooks, `review-commit-pr-discipline` prompt ([ADR-001](../decisions/ADR-001-git-commit-pr-discipline.md)) |
| v0.12.0 | 2026-06-05 | BONUS native Claude Code layer - `export-to-claude.sh` generator, `PreToolUse` cross-repo git guard, `.claude/` freshness enforcement |
| v0.11.0 | 2026-06-05 | Session isolation - `session-isolation.md`, `session-guard.sh`, `session-guard-check` hook |
| v0.10.0 | 2026-06-05 | Focus & branch discipline - `focus-and-branch-discipline.md`, `branch-check.sh`, `focus-guard` + `branch-hygiene-check` hooks, `docs/backlog/` queue |
