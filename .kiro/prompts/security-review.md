Run a periodic security review of the codebase.

1. Read `docs/security/SECURITY_LOG.md` to understand what's been reviewed before
2. Read `docs/roadmap/roadmap.md` to identify specs completed since the last SRR
3. Identify the next SRR number by checking `docs/security/` for existing reports
4. Run the code-security-reviewer audit scope: focus on files changed since the last review
5. For each finding:
   - Classify severity and category (S1-S9, Q1-Q3)
   - Describe the attack scenario concretely
   - Propose 2-3 remediation pathways with pros/cons
   - Recommend the best option with justification
6. Create `docs/security/SRR-{###}-{YYYY-MM-DD}.md` with the full report
7. Update `docs/security/SECURITY_LOG.md` with new findings
8. For CRITICAL/HIGH findings: create immediate fix tasks
9. For MEDIUM/LOW findings: add to roadmap as future items
10. Update `docs/roadmap/roadmap.md` security reviews table
