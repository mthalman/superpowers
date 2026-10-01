---
name: threat-modeling
description: Use when creating threat model documents for systems, services, or components - guides systematic user interview to gather comprehensive security information before documenting threats and mitigations using STRIDE methodology
---

# Threat Modeling

## Overview

Create threat model documents through systematic user interview. **Interview
first, document after.** Never assume; always ask.

## When to Use

- User requests a threat model for a system, service, or component.
- Security review or compliance work needs threat documentation.
- New system design needs security analysis.

## The Iron Law

```text
NO DOCUMENTATION WITHOUT COMPLETE INTERVIEW
```

Violations include making assumptions, listing all questions upfront, writing
threats before understanding the system, or stopping because the user seems busy.

## Interview Rules

1. Ask one question at a time.
2. Wait for the answer before proceeding.
3. Probe unclear answers with focused follow-up questions.
4. Do not assume. If the user does not know, record an open question.
5. Acknowledge time pressure, but do not skip critical security questions.

Open `references/threat-model-interview-checklist.md` when you need the detailed
phase-by-phase question checklist, gap handling, and redirection responses.

## Four-Phase Workflow

### Phase 1: System Overview

Understand what the system does, what components exist, external integrations,
deployment environment, users, security requirements, scope, assumptions,
valuable assets, and exposed entry points.

### Phase 2: Data and Trust Boundaries

Understand what data enters, leaves, and is stored; sensitivity levels; trust
boundaries; components inside each boundary; and external systems accessed for
the data-flow diagram.

### Phase 3: Security Controls

Understand authentication, authorization, secrets, cryptography, logging,
monitoring, compliance requirements, and third-party or supply-chain trust.

### Phase 4: Threat Analysis with STRIDE

For each major component and data flow, probe every STRIDE category:

| Category | Question pattern |
|---|---|
| **Spoofing** | What stops an attacker from impersonating X? |
| **Tampering** | What prevents modification of X in transit or at rest? |
| **Repudiation** | How do you prove X happened? Is there an audit trail? |
| **Information Disclosure** | What prevents unauthorized access to X? |
| **Denial of Service** | What happens if X is overwhelmed or unavailable? |
| **Elevation of Privilege** | What stops a user from gaining unauthorized access to Y? |

## Completion Gate Before Documenting

Do not write the threat model until all are true:

- All Phase 1-3 topics are answered or explicitly flagged as gaps.
- At least one STRIDE question has been asked per major component.
- The user confirms the interview summary covers the system.
- You can explain data flow from entry to exit.

Do not proceed if any core component lacks threat analysis,
authentication/authorization mechanisms are unknown, or data sensitivity levels
are unclear.

## Documenting the Threat Model

Open `references/threat-model-document-template.md` when the interview is
complete and you are ready to draft the threat model. Follow its structure and
keep risks tied to concrete components or flows.

Output must include:

- summary, scope, requirements, assumptions, and data-flow diagram;
- component or functional-area sections;
- inline **Risk** and **Mitigation** pairs;
- **TODO** entries for unresolved or incomplete mitigations;
- accepted risks and numbered action items.

## Quality Gate

Open `references/threat-model-quality-rubric.md` when reviewing the draft before
finalizing it. The final document must have one mitigation or explicit TODO for
every threat, no unstated assumptions, documented open questions, and actionable
numbered follow-ups.
