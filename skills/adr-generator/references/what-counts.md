# What Counts as an Architectural Decision?

Not every decision needs an ADR. This guide helps determine when to create an ADR versus when to just make a decision and move on.

## The Core Question

**Will this decision be hard to change later, and would future developers need to understand why it was made?**

If yes to both → Write an ADR
If no to either → Probably not worth an ADR

## Architectural vs Implementation Decisions

### Architectural Decisions (Write ADRs)

These are decisions that:
- Affect multiple components or the system structure
- Have significant cost to change later
- Involve trade-offs between quality attributes
- Set precedents for future work
- Have security, performance, or compliance implications
- Require team alignment

**Examples:**
- Database choice (PostgreSQL vs MongoDB)
- Authentication approach (JWT vs sessions)
- Monolith vs microservices
- REST vs GraphQL vs gRPC
- Cloud provider choice
- Third-party service integrations (Stripe, Auth0, etc.)
- Deployment strategy (containers, serverless, VMs)
- Testing strategy (unit vs integration test balance)
- Frontend framework choice
- API versioning strategy
- Caching architecture
- Message queue selection
- File storage approach (S3, local, CDN)

### Implementation Decisions (Skip ADRs)

These are decisions that:
- Are easily reversible
- Are localized to one component
- Follow established patterns
- Are temporary or tactical
- Can be changed without team discussion

**Examples:**
- Variable naming conventions (unless codifying for the whole team)
- Loop vs map for iteration in one function
- String formatting approach
- Specific color values in CSS
- Local refactoring within a module
- Which specific npm package for a utility (lodash vs ramda)
- Order of parameters in a function
- File organization within a small module
- Specific error message text
- Whether to use class or functional components in one feature

## Gray Areas: When It's Unclear

Some decisions fall in the middle. Consider these factors:

### Write an ADR if...

**Precedent-Setting**
- "If we choose X here, will we be expected to choose X everywhere?"
- Example: Using TypeScript for one new service → probably sets precedent for all new services

**Team Debate**
- "Did we have significant discussion about this?"
- If the team spent more than an hour debating it, document the conclusion

**Compliance or Security**
- "Does this affect how we handle user data or meet compliance requirements?"
- Example: Where/how to log sensitive data

**Cross-Team Impact**
- "Will other teams need to adapt to this decision?"
- Example: API design patterns that other teams will consume

**Cost to Reverse**
- "Would changing this decision require more than a day of work?"
- Example: Choosing a date/time library (affects many places, annoying to change)

### Skip an ADR if...

**Local and Temporary**
- "Is this decision contained to one feature that might be replaced anyway?"
- Example: Prototype code for a proof of concept

**Already Established Pattern**
- "Are we just following an existing pattern we already use?"
- Example: Using the same database as our other 10 services

**Implementation Detail**
- "Could we change this without anyone outside this module noticing?"
- Example: Data structure choice for an internal cache

**Obvious and Uncontroversial**
- "Did everyone immediately agree this was the right choice?"
- Example: Using HTTPS (not worth documenting "why HTTPS instead of HTTP")

## Decision Categories and Examples

### Always ADR-Worthy

**Technology Selection**
- Programming languages for new projects
- Major frameworks (React, Angular, Vue)
- Databases and data stores
- Cloud infrastructure choices
- CI/CD tooling

**System Structure**
- Service boundaries
- Module organization
- Layering and separation of concerns
- Communication patterns between components

**External Dependencies**
- Third-party SaaS integrations
- Payment processors
- Authentication providers
- Email/SMS services
- Monitoring and logging platforms

**Non-Functional Requirements**
- Performance optimization strategies
- Security architectures
- Reliability patterns (retries, circuit breakers)
- Scalability approaches
- Disaster recovery strategies

### Usually Not ADR-Worthy

**Coding Practices** (unless establishing team-wide standard)
- Comment styles
- Variable naming in one function
- Whether to use early return vs nested ifs

**Tactical Implementation**
- Algorithm choice for a single feature
- Data structure for internal state
- Specific library for a narrow use case
- UI layout details

**Obvious Choices**
- Using Git for version control
- Having a staging environment
- Writing automated tests

## The "Future Developer" Test

Ask yourself: **"If I left the company, would the next developer be confused about why we did this?"**

If yes → Write an ADR explaining the reasoning
If no → The code and comments are probably sufficient

### Examples of the Test in Action

**Scenario 1**: You choose PostgreSQL over MongoDB
- Future developer question: "Why SQL instead of NoSQL? Was MongoDB considered?"
- Answer: Yes, they'd wonder → Write an ADR

**Scenario 2**: You use Array.map instead of a for loop
- Future developer question: "Why map here?"
- Answer: No, it's a standard pattern → Skip ADR

**Scenario 3**: You use React Query instead of managing state manually
- Future developer question: "Why this library? What problem does it solve?"
- Answer: Depends on context. If it's used throughout the app and is a key pattern → ADR. If it's one feature → Skip

**Scenario 4**: You decide to not use microservices
- Future developer question: "Why is this all one service? Did we consider splitting it?"
- Answer: Yes, this is architectural → Write an ADR

## When in Doubt...

**Lean toward writing an ADR if:**
- Multiple people have strong opinions
- You're creating a precedent
- Money is involved (vendor choice, infrastructure cost)
- Security or compliance is relevant
- It took more than an hour to decide
- You'll explain this decision to new team members

**Lean toward skipping an ADR if:**
- It's trivially reversible
- Only you will ever touch this code
- It's following an existing pattern exactly
- Everyone agreed in under 5 minutes
- It's temporary or experimental code

## Examples: ADR or Not?

| Decision | ADR? | Reasoning |
|----------|------|-----------|
| Switch from REST to GraphQL for new API | ✅ Yes | Major architectural change affecting many teams |
| Use Prettier for code formatting | ✅ Yes | Team-wide tooling decision |
| Rename a function from `getUser` to `fetchUser` | ❌ No | Local refactoring, easily reversed |
| Use Stripe for payment processing | ✅ Yes | External dependency, costly to change |
| Use `const` instead of `let` for a variable | ❌ No | Implementation detail |
| Implement feature flags using LaunchDarkly | ✅ Yes | Infrastructure choice affecting deployment |
| Store timestamps in UTC | ✅ Yes | Data decision affecting entire system |
| Use kebab-case for CSS class names | ❌ No | Style guide, not architecture (unless codifying team standard) |
| Handle errors with try/catch vs error boundaries | ⚠️ Maybe | If establishing pattern → Yes. One component → No |
| Adopt event sourcing for order system | ✅ Yes | Significant architectural pattern with tradeoffs |
| Choose between `onClick` and `onPress` for one button | ❌ No | Implementation detail |
| Use Redis for session storage | ✅ Yes | Infrastructure component, affects reliability |
| Write `if (condition)` vs `if condition is true` | ❌ No | Code style, not architecture |
| Deploy to AWS instead of Azure | ✅ Yes | Major infrastructure decision |
| Use a specific shade of blue in the UI | ❌ No | Design detail, not architecture |

## Summary: The ADR Decision Tree

```
Is this decision...

1. Hard to change later?
   ├─ No → Skip ADR
   └─ Yes → Continue

2. Affecting multiple components or teams?
   ├─ No → Continue to #3
   └─ Yes → Write ADR

3. Did it take significant time/debate to decide?
   ├─ No → Continue to #4
   └─ Yes → Write ADR

4. Would a new team member wonder "why did they do it this way?"
   ├─ No → Skip ADR
   └─ Yes → Write ADR
```

When uncertain, remember: **It's better to have a few too many ADRs than to miss documenting a critical decision.**

A 10-minute ADR now can save hours of confusion later.
