# Threat Model Document Template

This reference provides the threat model structure to use after the interview completion gate passes.

Only write after the interview is complete. Follow this structure:

````markdown
# [Component/System Name] Threat Model

## Summary

[1-2 paragraph overview of what system does and how it works]

## Scope

### In Scope

[Components, services, and data flows covered by this threat model]

### Out of Scope

[Components explicitly excluded and why]

- Reference other threat models where applicable.
- Note components owned by other teams.

## Requirements

[List what the system must provide: confidentiality, integrity, availability, and so on]

## Assumptions

[Explicit list of trust assumptions: who is trusted, what access is assumed]

## Data Flow Diagram

```mermaid
flowchart TB
    subgraph [Trust Boundary Name]
        [Components within boundary]
    end

    [Component] -->|Data description| [Component]
```

Show:

- Trust boundaries as subgraphs.
- Components within each boundary.
- Data flows with labels describing what moves between components.
- External systems and where they cross trust boundaries.

## [Functional Area 1]

[Description of component/functionality]

**Risk**: [What could go wrong]

**Mitigation**: [How it's addressed]

**TODO**: [If mitigation incomplete - action item]

[Repeat Risk/Mitigation pairs inline with each functional area]

## [Functional Area 2]

[Continue pattern for each major component/flow]

## Data Flows

### [Flow Name]

[Source -> Processing -> Destination description]

**Risk**: [Attack vector for this flow]

**Mitigation**: [Defense]

## Trust Boundaries

[Where security decisions matter: network segments, auth boundaries]

## Data Serialization / Formats

[How data is encoded, what libraries, type safety concerns]

## Storage of Secrets

[How credentials/keys are protected, who has access]

## Use of Cryptography

[TLS configuration, encryption at rest, key management]

## Accepted Risks

[Risks explicitly not being mitigated and rationale]

- Document what's accepted and why.
- Note any conditions under which this should be revisited.

## Action Items

[Numbered list of TODOs identified during threat analysis]
````

## Key Format Rules

- Risk/Mitigation pairs go inline with component descriptions, not grouped
  separately.
- Use **Risk**: and **Mitigation**: bold markers.
- Add **TODO**: for unresolved items.
- Document assumptions early, after the summary.
- End with a numbered Action Items list.
