---
name: why
description: Investigate the historical motivation and constraints behind code, architecture, thresholds, regressions, or design choices. Use when the user asks why something was built this way, why one approach was chosen over another, where a number came from, what prior fixes failed, or whether the original rationale still applies. Do not use for explaining current runtime mechanics or diagnosing a new failure without a historical question.
---

# Why

Investigate intent through historical evidence. Code usually proves what the
system does, not why the team chose that behavior.

## Operating posture

- Collect evidence before forming a narrative.
- Cite every factual claim about intent.
- Label indirect conclusions as inference.
- Surface contradictions instead of selecting the convenient source.
- Present competing explanations when the record does not establish one.
- State which sources were unavailable or searched without relevant results.

A null search result means only that the stated search found nothing. It does
not prove that no record exists.

## Workflow

### 1. Define the question

Identify the target and the kind of rationale being requested:

- design choice or rejected alternative;
- defensive edge case;
- business, product, or compliance constraint;
- threshold or capacity number;
- regression or reverted fix;
- historical reason code still exists.

State the interpretation briefly when the target is ambiguous.

### 2. Establish a code anchor

Collect:

- relevant paths, lines, and symbols;
- blame commits for the governing lines;
- file history through renames;
- recent commits and associated PRs;
- linked issues, documents, or incidents.

Read enough current code to understand the anchor, but do not infer historical
intent from the implementation alone.

### 3. Build a source map

Inventory authorized and available evidence:

1. source control and code review;
2. issue or ticket tracking;
3. long-form specifications and decision records;
4. team discussions;
5. infrastructure metrics, logs, and incidents;
6. error tracking;
7. product analytics and experiment data.

Start with source control. Expand according to the question and material gaps.
Do not launch one agent per source when direct searches are sufficient.

For each source, record:

- tool or system searched;
- scope, terms, identifiers, and date range;
- direct findings;
- no relevant results;
- unavailable access or tooling.

Search only the current repository, organization, workspace, and sources the
user authorized.

### 4. Investigate independently

Use `dispatching-parallel-agents` for substantial independent evidence
categories. Give every investigator the same code anchor and historical
question. Keep raw private records within the authorized scope and return only
relevant findings with citations. Search directly when delegation would cost
more than the source investigation.

Verify citations before using them. A commit message, ticket, or chat statement
may be stale or contradicted by the implementation that shipped.

### 5. Calibrate conclusions

Classify each conclusion:

- **High confidence:** Direct, explicit, and consistent evidence tied to the
  shipped decision.
- **Medium confidence:** Multiple indirect signals support the same
  explanation, but no source states it completely.
- **Low confidence:** A plausible hypothesis with material gaps or competing
  explanations.

Do not let polished prose raise the confidence level.

### 6. Verify current relevance

Historical rationale can expire. Compare it with current code, constraints,
usage, and operational data. Distinguish:

- the reason the decision was made;
- whether that reason remains true;
- whether the current implementation still satisfies it.

## Report

Use this structure:

```markdown
## Question

<The historical question and interpreted target.>

## Code anchor

<Paths, lines, symbols, commits, and PRs.>

## Direct evidence

- <Claim, citation, and confidence>

## Reasonable inference

- <Inference chain and confidence>

## Competing hypotheses

- <Hypothesis, supporting evidence, opposing evidence>

## Unknowns

- <Unanswered question or material coverage gap>

## Sources consulted

- <Source, exact search scope, and result>
```

Omit **Competing hypotheses** only when direct evidence establishes one answer.

If the user intends to change the code, finish with:

- **Preserve:** Constraints still supported by evidence.
- **Change:** Historical assumptions that no longer apply.
- **Avoid:** Prior approaches whose failure conditions remain.
- **Risk:** Unresolved assumptions to test before editing.

Include a confidence level with every root-cause or rationale conclusion.
