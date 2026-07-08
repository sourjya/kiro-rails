---
name: incident-response
description: Security incident response, breach containment, evidence preservation, and recovery verification. Use when a breach, compromise, or security incident is detected or suspected.
---

# Incident Response Checklist

When a security incident is detected or suspected, follow this structured response. Do NOT improvise - skipping steps destroys evidence or widens the breach.

## Phase 1: Immediate Containment (first 15 minutes)

1. **Confirm the incident** - distinguish a real breach from a false alarm. Check: unauthorized access logs, unexpected data exfiltration, credential exposure, malware indicators, customer reports.
2. **Stop the bleeding** - contain without destroying evidence:
   - Revoke compromised credentials (API keys, tokens, passwords) - rotate, don't delete
   - Block attacker IPs/ranges at WAF or security group level
   - Disable compromised user accounts (suspend, don't delete)
   - Isolate affected systems (remove from load balancer, restrict network access)
3. **Preserve evidence BEFORE remediation:**
   - Snapshot affected EBS volumes, RDS instances, container filesystems
   - Export CloudTrail, VPC Flow Logs, application logs for the incident window
   - Screenshot or export any attacker-visible artifacts (defacement, unauthorized changes)
   - Record timestamps of discovery and each containment action
4. **Do NOT** reboot, redeploy, `git reset`, delete logs, or destroy state until evidence is preserved.

## Phase 2: Scope Assessment

1. **Determine blast radius:**
   - Which systems were accessed? (check auth logs, session records)
   - What data was exposed or exfiltrated? (check DB query logs, API access logs, S3 access logs)
   - How long was the attacker present? (earliest indicator → containment time)
   - Were other accounts/tenants affected? (cross-tenant leakage check)
2. **Identify the entry point:**
   - Credential compromise (which credential, how obtained)
   - Vulnerability exploitation (which endpoint, which CVE)
   - Social engineering / phishing (which user, what access)
   - Supply chain (which dependency, which version)
3. **Document in `docs/security/INCIDENT-{YYYY-MM-DD}.md`:**
   - Timeline of events
   - Systems affected
   - Data potentially exposed
   - Entry point and attack vector

## Phase 3: Communication

**Internal (within 1 hour of confirmation):**
- Engineering lead and security team
- Product/business owner of affected systems
- Legal counsel (if PII or regulated data involved)

**Customer notification (if required):**
- Determine regulatory obligation: GDPR (72h), HIPAA, state breach laws
- Draft factual notification: what happened, what data affected, what we're doing, what they should do
- Do NOT speculate - only state confirmed facts

**Template:**
```
Subject: Security Incident Notification - [Date]

What happened: [factual description of the incident]
When: [discovery time] - [containment time]
What data was affected: [specific data types, NOT "all your data"]
What we've done: [containment and remediation actions taken]
What you should do: [password reset, monitor accounts, etc.]
Next update: [specific time commitment]
```

## Phase 4: Remediation

1. Patch the vulnerability or close the attack vector
2. Force credential rotation for all potentially affected accounts
3. Deploy additional monitoring for the attack vector
4. Verify no persistence mechanisms remain (backdoors, new accounts, scheduled tasks, modified code)
5. Restore from known-good state if integrity cannot be verified

## Phase 5: Recovery Verification

Before declaring "all clear":
- [ ] Attack vector confirmed closed
- [ ] All compromised credentials rotated
- [ ] No unauthorized accounts, API keys, or SSH keys remain
- [ ] No scheduled tasks, cron jobs, or Lambda functions added by attacker
- [ ] No code modifications outside normal git history
- [ ] Monitoring in place to detect recurrence
- [ ] All affected systems restored to known-good state or verified clean

## Phase 6: Post-Incident Review

Within 5 business days, create a post-incident review covering:
1. **Timeline** - from initial compromise to full remediation
2. **Root cause** - not just "how" but "why our defenses didn't catch it"
3. **What worked** - detection mechanisms that fired, containment that was effective
4. **What failed** - gaps in monitoring, slow response, missing runbooks
5. **Action items** - specific changes to prevent recurrence (with owners and dates)
6. Store in `docs/security/POST-INCIDENT-{YYYY-MM-DD}.md`

## Anti-Patterns (BANNED during incidents)

- ❌ Rebooting or redeploying before preserving evidence
- ❌ Deleting attacker accounts/data (preserves evidence of their actions)
- ❌ `git reset --hard` on production (destroys audit trail)
- ❌ Communicating publicly before confirming facts
- ❌ Blaming individuals in written communications
- ❌ Assuming scope is limited without verifying
