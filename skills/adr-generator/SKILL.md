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

### 1. Determine If ADR Is Needed

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
