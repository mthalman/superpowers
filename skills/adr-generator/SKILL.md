---
name: adr-generator
description: Use when making architectural decisions that need documentation, after brainstorming explores trade-offs, or when code review reveals undocumented decisions - captures decision context, alternatives, and rationale in standardized Architecture Decision Record format at the moment decisions are made
---

# Architecture Decision Record Generator

## Overview

Capture architectural decisions when they're made, not months later when context is lost. This skill helps document significant technical decisions using the Architecture Decision Record (ADR) pattern, making it easy to understand why systems are built the way they are.

## When to Use This Skill

Use this skill when:

**Making architectural decisions:**
- Choosing between technology options (databases, frameworks, languages)
- Deciding on system structure (monolith vs microservices, API patterns)
- Selecting third-party services or integrations
- Establishing patterns that will affect multiple components
- Making decisions with security, performance, or compliance implications

**After brainstorming:**
- Brainstorming explored alternatives and trade-offs
- Decision has been made and needs to be documented
- Context and rationale are fresh and should be captured

**During code review:**
- Reviewer asks "why did you do it this way?"
- Implicit decision should be made explicit
- Pattern-setting choice that others should follow

**Before implementation:**
- Team needs alignment on approach before building
- Need to document the "why" before writing the "what"

## Workflow

### 0. Experiments vs Architectural Decisions

**Is this a prototype/spike/experiment?**

Before creating an ADR, determine if you're documenting an experiment or an architectural decision:

**EXPERIMENT:** Exploring what's possible, learning, prototyping
- Requirements unclear or unstable
- May pivot, cancel, or discard work
- Goal is learning, not production deployment

**ARCHITECTURAL DECISION:** Committing to ship/deploy something
- Decision to use technology in production
- Affects production system boundaries
- Other teams will depend on this

**The key distinction:** The architectural decision is "**use in production**," not "**try in prototype**."

---

#### If EXPLORING (not shipping yet):

Create `experiments/YYYY-MM-description.md` instead of ADR.

**Experiment Log Template:**

```markdown
# Experiment: [Description]

## Status
In Progress / Completed / Abandoned

## Goal
[What we're trying to learn or validate]

## Hypothesis
[What we think will work and why]

## Approach
- Technology: [What we're testing]
- Timeline: [How long for spike]
- Success Criteria: [How we'll know if it works]

## Findings
[Update as you learn - what worked, what didn't, metrics, observations]

## Decision Point
**IF this experiment succeeds AND we decide to ship to production:**
- Create ADR for production technology choice
- Re-evaluate with production criteria (scale, cost, operations, SLAs)
- The ADR will document the shipping decision, not the experiment

## References
- Branch: [link]
- Test data: [location]
- Related experiments: [links]
```

**Why experiment logs instead of ADRs:**
- Prototypes need different documentation practices than production
- Prevents ADR bloat (50 prototype ADRs, 3 production decisions)
- Reduces documentation burden that discourages experimentation
- Keeps signal-to-noise ratio high for ADRs

**When to promote experiment to ADR:**
Only when experiment succeeds AND you decide to ship to production. At that point:
1. Create new ADR: "Production [Technology] for [Feature]"
2. Reference experiment log as context
3. Frame decision as: "Should we ship this experiment?"
4. Re-evaluate with production criteria (not just prototype experience)

---

#### If SHIPPING (promoting experiment to production):

Now create an ADR.

**Key points:**
- The experiment choice itself isn't the ADR subject
- The shipping decision is the architectural decision
- Include experiment log as context
- Evaluate with production requirements (scale, cost, SLAs, operations)

**Example:**
- Experiment log: `experiments/2025-12-vector-search-spike.md` (used Pinecone for quick testing)
- ADR: "ADR-0015: Production Vector Database for AI Search Feature" (may choose different technology after production evaluation)

---

#### Pre-ADR Gate: Is There Actually a Decision?

Before creating ANY ADR, verify:

✅ **Decision is actually made**
- "We are shipping X to production" → ADR
- "We might try X in a prototype" → Experiment log
- "We're exploring X vs Y" → Experiment log

✅ **Decision is binding**
- Other teams will depend on this → ADR
- Only affects one prototype → Experiment log
- Production system boundaries change → ADR

✅ **This is architecture vs implementation**
- Changes system structure or interfaces → ADR
- Internal to one component → Code comments

**Don't abuse status fields to force experiments into ADR format.**

If uncertain, use experiment log first. You can always promote to ADR later if you ship.

---

### 1. Determine If ADR Is Needed

⚠️ **COGNITIVE CHECKPOINT: Before creating an ADR**

You must be able to articulate:
- **WHY** this decision is significant (not just a local implementation detail)
- **WHAT** will be harder to change if we don't document this now
- **WHO** will need to understand this decision in the future

If you cannot clearly articulate significance → This likely doesn't need an ADR
If you can clearly articulate → Proceed with ADR creation

Not every decision needs an ADR. Ask:
- Will this decision be hard to change later?
- Would future developers need to understand why it was made?
- Does this affect multiple components or teams?
- Did this require significant discussion or debate?

**If unsure, read `references/what-counts.md` for detailed guidance.**

Quick examples:
- ✅ Database choice (PostgreSQL vs MongoDB) → ADR
- ✅ Authentication approach (JWT vs sessions) → ADR
- ❌ Variable naming in one function → No ADR
- ❌ Using map vs for loop in one place → No ADR

### 2. Create ADR File

Use the `New-ADR.ps1` script to create a new ADR.

**Script location:** `scripts/New-ADR.ps1`

**Run from project root:**
```powershell
# Basic usage (proposed status)
pwsh scripts/New-ADR.ps1 -Title "Use PostgreSQL for primary database"

# With options
pwsh scripts/New-ADR.ps1 `
    -Title "Use PostgreSQL for primary database" `
    -Status Accepted `
    -DecisionsPath "docs/architecture/decisions"
```

**Run from skill directory:**
```powershell
# If already in skills/adr-generator/
pwsh scripts/New-ADR.ps1 -Title "Use PostgreSQL for primary database"
```

**Parameters:**
- `Title`: Decision title (required)
- `Status`: `Proposed`, `Accepted`, `Deprecated`, `Superseded`, `Rejected`. Default: `Proposed`
- `DecisionsPath`: Where to create ADR files. Default: `docs/decisions`

The script:
1. Finds existing ADRs and assigns next number (e.g., 0005)
2. Creates file: `docs/decisions/0005-use-postgresql-for-primary-database.md`
3. Fills template with title, date, and status
4. Returns filepath for editing

### 3. Fill In ADR Content

Open the created file and complete the template sections:

- **Context and Problem Statement**: Describe the situation and articulate the problem as a question
- **Decision Drivers**: Forces influencing the decision (team constraints, business needs, technical requirements)
- **Considered Options**: List all alternatives explored (bullet list)
- **Decision Outcome**: Chosen option with justification
- **Positive Consequences**: Benefits and improvements from this decision
- **Negative Consequences**: Trade-offs and what becomes harder
- **Pros and Cons of Options**: Detailed comparison matrix of all alternatives (see guidance below)

**Read `references/examples.md` for well-written ADR examples.**

---

#### Contextualizing Your Decision (Team, Organization, and Architectural Principles)

**Before writing the ADR, gather context that shapes the decision:**

##### Team Context

Consider team-specific factors that affect technology choices:

- **Team expertise:** What technologies does the team have deep experience with?
  - Example: "Team has 5 years production PostgreSQL experience"
  - Impact: Reduces risk, accelerates delivery, affects operational burden

- **Team size/maturity:** How does team composition affect operational choices?
  - Small team (1-5) → Prefer managed services, boring technology
  - Large team (20+) → Can handle operational complexity
  - Junior team → Simpler technologies, less operational burden

- **On-call burden tolerance:** Who maintains this?
  - Small team with limited on-call → Managed services, proven technology
  - Dedicated SRE team → More operational complexity acceptable

##### Organization Context

Consider organizational factors:

- **Existing technology stack:** What's already in production?
  - Example: "PostgreSQL already used for 3 other services"
  - Benefit: Reuse operational expertise, shared monitoring, consistent tooling
  - Cost: Adding new database type increases operational complexity

- **Engineering principles:** What principles guide decisions?
  - Examples: "Boring technology," "API-first," "Optimize for deletion"
  - Reference by name if documented
  - Link to principle documentation if available

- **Risk tolerance:** What's acceptable risk level?
  - Startup experimenting → Higher tolerance for novel technology
  - Enterprise banking → Prefer proven, battle-tested solutions
  - Regulated industry → Compliance requirements constrain choices

##### Operational Context

- **Maintenance expectations:** Who operates this long-term?
  - Team that builds it maintains it → Choose tech team can operate
  - Dedicated ops team → Can handle more complexity
  - No ops team → Managed services preferred

- **Operational maturity requirements:** What's the SLA?
  - Experimental feature → Lower operational maturity acceptable
  - Critical path service → Proven technology, robust monitoring
  - Internal tool → Different requirements than customer-facing

- **Support availability:** What support exists?
  - 24/7 on-call → Boring technology with known failure modes
  - Business hours only → Simpler systems, less critical
  - No dedicated support → Self-healing, managed services

##### Referencing Architectural Principles

**Common established principles:**

- **"Boring technology" (Dan McKinley):** Prefer proven over novel to conserve "innovation tokens"
- **"Optimize for deletion":** Prefer reversible decisions, minimize long-term commitments
- **"Convention over configuration":** Reduce decisions by following standards
- **"Worse is better":** Pragmatic simplicity over theoretical perfection
- **"You build it, you run it":** Team expertise shapes technology choices

**How to reference principles:**

```markdown
## Decision Drivers

- Team has PostgreSQL production experience (3 services)
- Aligns with "boring technology" principle: conserve innovation for differentiating features
- "You build it, you run it": choosing technology team can operate
- Budget constraints favor open-source solutions
```

**Benefits of referencing principles:**
- Connects decision to broader engineering culture
- Avoids re-explaining foundational reasoning
- Provides decision-making framework for future choices

##### Format Alternatives with Context

**❌ Generic, context-free:**
```markdown
### PostgreSQL

Relational database with good performance and ACID compliance.

* Good, because good performance
* Good, because ACID support
* Bad, because vertical scaling limits
```

**✅ Contextualized with team/org factors:**
```markdown
### PostgreSQL

Relational database with JSON support and full ACID compliance.

* Good, because team has 5 years production experience (reduces operational risk)
* Good, because already in stack for 3 other services (reuse monitoring, runbooks, expertise)
* Good, because strong ACID guarantees needed for financial transactions
* Good, because aligns with "boring technology" principle for non-differentiating infrastructure
* Bad, because vertical scaling limits (may need sharding beyond 1M transactions/day)
* Bad, because team needs to learn PostgreSQL-specific features (JSONB indexing, query optimization)
```

**Principle:** Alternatives analysis without team/org context is academic, not architectural. Architecture exists in organizational context.

---

#### How to Write "Pros and Cons of Options"

This section is the most important and requires one subsection per considered option.

**Structure for each option:**
```markdown
### [Option Name]

[One sentence describing what this option is]

* Good, because [specific benefit]
* Good, because [specific benefit]
* Good, because [specific benefit]
* Bad, because [specific drawback]
* Bad, because [specific drawback]
* Bad, because [specific drawback]
```

**Guidelines:**
- Create one subsection (### heading) for EACH option from "Considered Options"
- Start with brief description (1 sentence) of what the option is
- List "Good, because..." items first
- Then list "Bad, because..." items
- Be specific: "Good, because team has SQL experience" not "Good, because familiar"
- Include 3-6 items per option (both Good and Bad)
- Order doesn't matter within Good/Bad lists

**How to extract from brainstorming:**
- Context section → "Good, because..." points discussed
- Trade-offs section → "Bad, because..." points discussed
- Alternatives section → Different options and their characteristics

**Example:**
```markdown
### PostgreSQL

Relational database with JSON support and full ACID compliance.

* Good, because native JSONB support handles both structured and semi-structured data
* Good, because strong ACID guarantees for financial transactions
* Good, because team has SQL experience
* Bad, because vertical scaling limits
* Bad, because requires operational expertise
```

**Common mistakes:**
- ❌ Only listing pros for chosen option
- ❌ Vague reasons: "Good, because better"
- ❌ Skipping description sentence
- ❌ Not covering all considered options

**Why this section matters:** Future developers need to see ALL options were evaluated, understand trade-offs, and know why rejected options weren't chosen.

### 4. Commit the ADR

After filling in the ADR content, commit it to version control:

```bash
git add docs/decisions/0005-use-postgresql-for-primary-database.md
git commit -m "docs: add ADR-0005 for PostgreSQL database choice"
```

**Why commit immediately:**
- Makes ADR available to team members
- Creates audit trail of when decision was made
- Prevents loss if work is abandoned
- Integrates decision into project history

**Commit message format:**
- Use `docs:` prefix for ADR commits
- Include ADR number in message
- Brief description of decision

## Integration with Other Skills

### With Brainstorming Skill

**Natural handoff:**
1. User: "Should we use PostgreSQL or MongoDB?"
2. Use brainstorming skill to explore alternatives and trade-offs
3. After brainstorming reaches conclusion, use this skill to document decision
4. ADR captures: context from brainstorming, alternatives explored, decision rationale

**Example:**
```
[After brainstorming session]
"The brainstorming session identified PostgreSQL as the best choice for our use case.
Let me use the adr-generator skill to document this decision."

[Creates ADR capturing the alternatives and reasoning from brainstorming]
```

### With Receiving Code Review Skill

**When reviewer questions a decision:**
1. Reviewer: "Why did you use Redis here instead of database caching?"
2. If no ADR exists for this choice, recognize it as an architectural decision
3. Use this skill to create ADR documenting the reasoning
4. Makes implicit decisions explicit for future reviewers

**Example:**
```
Reviewer asks: "Why JWT instead of sessions?"
If this wasn't documented, use adr-generator to create:
"ADR-0015: Use JWT with Refresh Tokens for Authentication"
```

### With Verification Before Completion Skill

**Before claiming work is complete:**
- Check if any architectural decisions were made during implementation
- If yes, ensure they're documented in ADRs
- Don't merge without documenting significant choices

## ADR Template Structure

This skill uses the MADR (Markdown Any Decision Records) template format, which provides structured sections for comprehensive decision documentation:

**Sections:**
- **Status**: Current state (Proposed, Accepted, Deprecated, Superseded, Rejected)
- **Context and Problem Statement**: What problem or situation motivates this decision?
- **Decision Drivers**: Forces influencing the choice (constraints, requirements, priorities)
- **Considered Options**: All alternatives that were evaluated
- **Decision Outcome**: Chosen option with clear justification
- **Positive Consequences**: Benefits and what becomes easier
- **Negative Consequences**: Trade-offs and what becomes harder
- **Pros and Cons of Options**: Detailed comparison matrix showing why each option was/wasn't chosen
- **Links**: References to related ADRs or external resources

This structured format ensures all relevant context is captured, making it easy for future developers to understand both what was decided and why.

## Maintaining an ADR Index (Optional)

For projects with many ADRs, maintain an index file for easy navigation.

**Template available:** `assets/decision-log-index.md`

**Location:** `docs/decisions/README.md` or `docs/decisions/INDEX.md`

**Contents:**
- Table listing all ADRs with number, title, status, date
- Link to each ADR file
- Status legend

**Example:**
```markdown
# Architecture Decision Records

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [ADR-0001](0001-record-architecture-decisions.md) | Record architecture decisions | Accepted | 2024-01-15 |
| [ADR-0002](0002-use-postgresql.md) | Use PostgreSQL for primary database | Accepted | 2024-02-03 |
| [ADR-0003](0003-jwt-authentication.md) | Use JWT with refresh tokens | Accepted | 2024-02-10 |
```

**When to create:**
- After 5+ ADRs exist
- When team has trouble finding ADRs
- For onboarding new developers

**Maintenance:**
- Update manually when creating new ADRs
- Or use script to auto-generate from ADR files
- Include in PR review checklist

## ADR Statuses

Track decision lifecycle with these statuses:

- **Proposed**: Decision under consideration, not yet approved
- **Accepted**: Decision has been approved and is active
- **Deprecated**: Decision no longer current but kept for historical context
- **Superseded**: Replaced by a newer ADR (link to new one)
- **Rejected**: Considered but rejected (rare, usually just not proposed)

### Status Transitions

**Proposed → Accepted**
- When: Decision is approved and team commits to implementation
- How: Edit ADR file, change status from "Proposed" to "Accepted"
- Commit: `git commit -m "docs: accept ADR-0005 (PostgreSQL choice)"`

**Proposed → Rejected**
- When: After review, decision is not approved
- How: Edit ADR file, change status to "Rejected", add rejection rationale
- Note: Rare - usually just don't create the ADR if rejected during proposal
- Commit: `git commit -m "docs: reject ADR-0007 (GraphQL adoption)"`

**Accepted → Deprecated**
- When: Decision is no longer recommended but not replaced by specific new decision
- How: Edit ADR file, change status to "Deprecated", explain why no longer recommended
- Example: "Technology reached end-of-life" or "Pattern caused issues in practice"
- Commit: `git commit -m "docs: deprecate ADR-0003 (Redis caching pattern)"`

**Accepted → Superseded**
- When: New ADR replaces this decision
- How:
  1. Create new ADR (e.g., ADR-0020) with updated decision
  2. Edit old ADR file, change status to "Superseded by ADR-0020"
  3. Add link to new ADR in Links section
  4. New ADR should reference old one: "Supersedes ADR-0005"
- Commit old: `git commit -m "docs: supersede ADR-0005 (replaced by ADR-0020)"`
- Commit new: `git commit -m "docs: add ADR-0020 (MongoDB adoption)"`

**Status Change Guidelines:**
- Always explain WHY status changed in commit message or ADR body
- Don't delete old ADRs - they preserve decision history
- Link related ADRs when superseding
- Keep old content intact (immutable record)

---

### Cultural Framing for Superseding Decisions

**How you document superseded decisions affects organizational learning culture.**

When creating a new ADR that supersedes an old decision, language matters for psychological safety and learning culture.

#### Language Guidelines

❌ **Avoid blame-implying language:**
- "Why [old choice] was wrong"
- "Problems with [old decision]"
- "Fixing the [old choice] mistake"
- "[Old technology] failed us"

✅ **Use context-change framing:**
- "What changed since we chose [old choice]"
- "Why [old choice] was right then, but circumstances shifted"
- "Evolution from [old] to [new]"
- "Our needs evolved beyond [old choice]'s strengths"

#### Required Sections When Superseding

**1. Historical Context Section**

```markdown
## Historical Context (Reference ADR-XXXX)

In [year], we chose [old technology] for the following reasons (from ADR-XXXX):
- [Reason 1 from original ADR]
- [Reason 2 from original ADR]
- [Reason 3 from original ADR]

**What has changed since ADR-XXXX:**
1. **Scale:** [How growth changed requirements]
2. **Requirements:** [What new needs emerged]
3. **Use patterns:** [How actual usage differed from expectations]
4. **Team expertise:** [How team capabilities evolved]

**ADR-XXXX was the correct decision at the time.** [Explain why it made sense then]
```

**2. Lessons Learned Section**

```markdown
## Lessons Learned

**What we learned from this evolution:**
- [Insight 1]: [What this experience taught us]
- [Insight 2]: [What we'd consider differently next time]
- [Insight 3]: [How our understanding evolved]

**This is not a reversal of a "mistake"** - it's natural evolution as:
- Requirements became clearer
- Scale revealed different needs
- Team and system matured
```

**3. Update Old ADR with Respectful Language**

Add to the TOP of the old ADR (ADR-XXXX):

```markdown
**Status**: Superseded by ADR-YYYY: [New Decision Title] (YYYY-MM-DD)

**Note**: This decision was appropriate for our context in [year] ([brief context]).
As of [current year], our needs evolved to require [new capability].
See ADR-YYYY for details on what changed and why.
```

#### Cultural Principles

**Protect past decision-makers:**
- Frame as learning, not fixing mistakes
- Validate original reasoning explicitly
- Explain what changed externally (scale, requirements), not what was "wrong" internally

**Promote honest documentation:**
- If teams fear blame for "wrong" decisions, they document defensively or not at all
- Context-change framing encourages transparency

**Encourage revisiting decisions:**
- Healthy teams adapt to new information
- Framing evolution positively makes it safe to change course

#### Example: Context-Change vs Blame Framing

**❌ Blame framing:**
```markdown
## Why MongoDB Failed

MongoDB couldn't handle our transaction requirements and caused data consistency issues.
We're fixing this by migrating to PostgreSQL.
```

**✅ Context-change framing:**
```markdown
## Historical Context (Reference ADR-0003)

In 2023, we chose MongoDB for schema flexibility during rapid MVP iteration (see ADR-0003).

**What has changed since ADR-0003:**
- Scale grew 10x (50K → 500K users)
- Requirements: ACID needs emerged for payment workflows
- Use patterns: Queries became relational (complex joins), fighting document model
- Schema: Stabilized after 6 months, flexibility less critical

**ADR-0003 was the correct decision at the time.** Schema flexibility enabled rapid
feature iteration in our MVP phase. Our needs evolved as the system matured.

## Lessons Learned

- Document model works well for early-stage flexibility
- Relational patterns emerge at scale with stable schemas
- Next time: Consider transaction patterns earlier in database evaluation
```

#### When Context Actually Changed vs When Decision Was Flawed

**Be honest if the original decision was flawed:**

If, in retrospect, the original decision missed obvious considerations:

```markdown
## Reflection on ADR-XXXX

**In retrospect:** ADR-XXXX underestimated [factor] that was knowable at the time.

**What we missed:**
- [Consideration that should have been evaluated]
- [Risk that was foreseeable but not assessed]

**What we'd do differently:**
- [Specific process improvement]
- [Additional evaluation step]

**Learning:** This isn't about blame - it's about improving our decision-making process.
```

**Principle:** Honesty about mistakes is fine, but frame as process learning, not individual fault.

---

## Reference Documentation

### `references/examples.md`

Contains complete, real-world examples of well-written ADRs:
- Database choice (PostgreSQL vs MySQL vs MongoDB)
- Architecture pattern (monolith vs microservices)
- Authentication approach (JWT with refresh tokens)
- API versioning strategy

**When to load:** Writing first ADR, unsure how much detail to include, want to see good examples.

**How to load:**
```
Read references/examples.md
```

### `references/what-counts.md`

Comprehensive guide for determining when to create an ADR:
- Architectural vs implementation decisions
- Decision categories and examples
- Gray areas and decision tree
- "Future developer test"

**When to load:** Unsure if decision warrants an ADR, debating with team about documentation, establishing ADR practice.

**How to load:**
```
Read references/what-counts.md
```

## Common Patterns

### Pattern 1: End-to-End Example (Brainstorming → ADR)

**Scenario:** User asks "Should we use PostgreSQL or MongoDB for our database?"

**Step 1: Brainstorming session**
```
User: "Should we use PostgreSQL or MongoDB?"

Claude (using brainstorming skill):
- Asks about requirements: ACID needs? JSON data? Team experience?
- Proposes alternatives: PostgreSQL, MongoDB, MySQL
- Explores trade-offs:
  - PostgreSQL: Strong ACID, JSON support, team knows SQL
  - MongoDB: Flexible schema, horizontal scaling, no ACID across docs
  - MySQL: Mature, team knows it, weaker JSON support
- User chooses: PostgreSQL
```

**Step 2: Recognize architectural decision**
```
Claude: "This database choice is an architectural decision that should be documented.
Let me use the adr-generator skill to create an ADR."
```

**Step 3: Create ADR file**
```powershell
pwsh scripts/New-ADR.ps1 -Title "Use PostgreSQL for primary database"
# Creates: docs/decisions/0003-use-postgresql-for-primary-database.md
```

**Step 4: Fill ADR from brainstorming context**
```markdown
## Context and Problem Statement
We need a database for user data, product catalog, and transactions. Requirements include
ACID compliance, JSON support, and team familiarity.

What database should we use that balances structured and flexible data needs?

## Decision Drivers
* Need ACID guarantees for transactions
* Team has SQL experience
* Require JSON support for flexible product attributes
* Budget constraints favor open-source

## Considered Options
* PostgreSQL
* MongoDB
* MySQL

## Decision Outcome
Chosen option: "PostgreSQL", because it provides ACID + JSONB + team expertise.

## Positive Consequences
* JSONB handles structured and flexible data
* Strong ACID compliance
* Team already knows SQL

## Negative Consequences
* Vertical scaling limitations
* Requires index tuning
* Team needs to learn PostgreSQL-specific features

## Pros and Cons of the Options

### PostgreSQL
Relational database with JSON support.
* Good, because JSONB support for flexible schemas
* Good, because strong ACID guarantees
* Good, because team has SQL experience
* Bad, because vertical scaling limits
* Bad, because operational complexity

### MongoDB
Document-oriented NoSQL database.
* Good, because excellent flexible schema
* Good, because horizontal scaling built-in
* Bad, because no ACID across documents (deal-breaker)
* Bad, because team needs to learn NoSQL patterns

### MySQL
Popular relational database.
* Good, because team has SQL experience
* Good, because mature ecosystem
* Bad, because weaker JSON support than PostgreSQL
* Bad, because less powerful full-text search
```

**Step 5: Commit**
```bash
git add docs/decisions/0003-use-postgresql-for-primary-database.md
git commit -m "docs: add ADR-0003 for PostgreSQL database choice"
```

**Key insight:** All the content for the ADR (context, alternatives, pros/cons) came from the brainstorming session. The ADR is just organizing that context into the structured format.

### Pattern 2: Question → Recognize → Document

```
1. Reviewer asks: "Why did you do this?"
2. Recognize: This was an architectural decision
3. Use adr-generator skill: Create ADR with reasoning
```

### Pattern 3: Multiple Related Decisions

```
1. Make primary decision (e.g., "Use microservices")
2. Document with ADR-0010
3. Subsequent decisions reference it:
   - ADR-0011: Service communication pattern (references ADR-0010)
   - ADR-0012: Service discovery approach (references ADR-0010)
```

### Pattern 4: Superseding Old Decisions

```
1. Context changes, old decision no longer appropriate
2. Create new ADR-0020 with updated decision
3. Update ADR-0005 status to "Superseded by ADR-0020"
4. New ADR explains why previous decision was superseded
```

## Best Practices

**Be honest about consequences:**
- Every decision has trade-offs
- Document both positive and negative outcomes
- Include what becomes harder, not just what becomes easier

**Capture decision drivers:**
- Team constraints (size, experience)
- Business constraints (budget, timeline)
- Technical constraints (existing systems, requirements)
- Quality attributes (performance, security, scalability)

**Link related ADRs:**
- Reference previous ADRs that influence this decision
- Note follow-up decisions that will be needed
- Build a web of related architectural choices

**Keep ADRs immutable:**
- Don't edit ADRs after they're accepted (except typos)
- If decision changes, create new ADR that supersedes old one
- Preserves historical record of decision evolution

**Write for future developers:**
- Assume reader has no context about the project
- Explain acronyms and project-specific terms
- Include enough detail to understand the reasoning

## Anti-Patterns to Avoid

❌ **Documenting after implementation**
- Context is forgotten, alternatives are lost
- Write ADRs when decisions are made

❌ **Skipping alternatives**
- ADR should show other options were considered
- Empty "alternatives" section suggests hasty decision

❌ **Only positive consequences**
- Every choice has downsides
- Honest about trade-offs builds trust

❌ **Too vague**
- "We chose X because it's better" isn't useful
- Include specific reasons and constraints

❌ **Treating ADRs as implementation docs**
- ADR explains "why", not "how"
- Implementation details belong in code/comments

❌ **Changing ADRs after acceptance**
- Creates confusion about what was actually decided
- Create new ADR that supersedes old one instead

## Troubleshooting

**"I'm not sure if this needs an ADR"**
→ Read `references/what-counts.md` and use the decision tree

**"I don't know what alternatives to list"**
→ If you didn't consider alternatives, maybe don't make the decision yet. Read `references/examples.md` for inspiration.

**"We need to change an existing ADR"**
→ Don't edit it. Create new ADR that supersedes the old one.

**"Team won't read these"**
→ Reference ADRs in code reviews, onboarding docs, and implementation plans. Make them discoverable.

## Quick Reference

**Create ADR (from project root):**
```powershell
pwsh scripts/New-ADR.ps1 -Title "Your decision title"
```

**With options:**
```powershell
pwsh scripts/New-ADR.ps1 `
    -Title "Decision title" `
    -Status Accepted `
    -DecisionsPath "docs/architecture/decisions"
```

**Read examples:**
```
Read references/examples.md
```

**Decide if needed:**
```
Read references/what-counts.md
```

**Commit ADR:**
```bash
git add docs/decisions/0005-your-decision.md
git commit -m "docs: add ADR-0005 (your decision)"
```
