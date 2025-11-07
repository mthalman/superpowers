# Example Architecture Decision Records

This document provides examples of well-written ADRs across different domains to illustrate good practices.

## Example 1: Database Choice

### ADR-0003. Use PostgreSQL for Primary Database

Date: 2024-03-15

#### Status

Accepted

#### Context and Problem Statement

We need to choose a database for our application that will handle user data, product catalog, and order transactions. Our application requires ACID compliance for financial transactions, support for complex queries with joins, JSON data for flexible product attributes, and full-text search capabilities. We anticipate 100K users in year one, growing to 1M+ users by year three.

What database technology should we use that balances our need for structured transaction data with flexible product attributes, while meeting performance and reliability requirements?

#### Decision Drivers

* Need ACID guarantees for order processing
* Development team has strong SQL experience
* Require both structured (orders) and semi-structured (product attributes) data
* Budget constraints favor open-source solutions
* Need mature ecosystem with good tooling support
* Anticipated scale: 100K users year 1, 1M+ by year 3

#### Considered Options

* PostgreSQL
* MySQL
* MongoDB
* Amazon DynamoDB

#### Decision Outcome

Chosen option: "PostgreSQL", because it provides the best combination of ACID compliance, JSON support (JSONB), team expertise, and cost-effectiveness. It's the only option that handles both structured and semi-structured data natively while maintaining strong transaction guarantees.

#### Positive Consequences

* Native JSONB support handles both structured and flexible data models
* Strong ACID compliance ensures transaction integrity
* Excellent full-text search with built-in capabilities
* Team familiarity reduces development time
* Rich extension ecosystem (PostGIS if we need geospatial features later)
* Cost-effective (open-source, runs on standard infrastructure)

#### Negative Consequences

* Vertical scaling limitations compared to distributed databases (mitigated: not expected to hit limits in 3-year horizon)
* Requires careful index management for optimal performance
* Must plan backup/replication strategy
* Team needs to learn PostgreSQL-specific features (JSONB operators, CTEs, etc.)

#### Pros and Cons of the Options

##### PostgreSQL

Relational database with JSON support and full ACID compliance.

* Good, because native JSONB support handles both structured and semi-structured data
* Good, because strong ACID guarantees for financial transactions
* Good, because team has SQL experience and PostgreSQL expertise
* Good, because mature ecosystem with excellent tooling
* Good, because open-source with no licensing costs
* Good, because built-in full-text search
* Bad, because vertical scaling limits (eventual bottleneck)
* Bad, because requires operational expertise for tuning and optimization

##### MySQL

Popular open-source relational database.

* Good, because mature and widely adopted with large community
* Good, because team has SQL experience
* Good, because JSON support (though less mature than PostgreSQL)
* Good, because open-source
* Bad, because JSON support is less feature-rich than PostgreSQL
* Bad, because full-text search less powerful than PostgreSQL
* Bad, because historically weaker transaction support (improved in recent versions)
* Bad, because team less familiar with MySQL-specific features

##### MongoDB

Document-oriented NoSQL database.

* Good, because excellent flexible schema support (document model)
* Good, because horizontal scaling built-in
* Good, because simple JSON-like documents
* Bad, because no ACID transactions across documents (deal-breaker for financial data)
* Bad, because team would need to learn NoSQL patterns
* Bad, because complex queries less powerful than SQL joins
* Bad, because eventual consistency model risky for financial transactions

##### Amazon DynamoDB

Fully managed NoSQL database service.

* Good, because fully managed (no operational overhead)
* Good, because automatic scaling
* Good, because high availability built-in
* Bad, because expensive at our anticipated scale
* Bad, because vendor lock-in to AWS
* Bad, because no ACID transactions across items
* Bad, because limited query capabilities compared to SQL
* Bad, because team would need to learn NoSQL and DynamoDB-specific patterns

#### Links

* [ADR-0004](0004-postgresql-replication-strategy.md) - PostgreSQL replication strategy
* [ADR-0005](0005-backup-and-disaster-recovery.md) - Backup and disaster recovery approach

## Example 2: Monolith vs Microservices

### ADR-0002. Start with Modular Monolith

Date: 2024-02-10

#### Status

Accepted

#### Context and Problem Statement

We are building a new e-commerce platform with distinct domains: user management, product catalog, shopping cart, order processing, payment integration, and inventory management. The team consists of 4 engineers, and we need to launch an MVP in 3 months.

Should we start with a microservices architecture or a monolithic architecture, given our team size, timeline constraints, and uncertain domain boundaries?

#### Decision Drivers

* Small team size (4 engineers)
* Tight timeline (3 months to MVP)
* Uncertain domain boundaries at this stage
* Team has limited distributed systems experience
* Need to iterate quickly based on user feedback
* Cost constraints (infrastructure and operational overhead)

#### Considered Options

* Traditional monolith
* Modular monolith with clear boundaries
* Microservices from day one
* Serverless functions

#### Decision Outcome

Chosen option: "Modular monolith with clear boundaries", because it provides the fastest path to MVP while maintaining flexibility to extract services later. It avoids distributed system complexity while still enforcing good architectural boundaries that will ease future evolution.

#### Positive Consequences

* Faster initial development (no distributed system complexity)
* Easier debugging and testing (single deployment unit)
* Simpler deployment pipeline
* Lower operational complexity
* Can refactor module boundaries easily while learning the domain
* Modules can be extracted to services later if needed
* Single database simplifies transactions across domains

#### Negative Consequences

* Risk of tight coupling if discipline isn't maintained
* All modules must share the same technology stack
* Entire app must be deployed for any change (mitigated: planning CI/CD for fast deploys)
* Scaling requires scaling the entire application

#### Pros and Cons of the Options

##### Traditional Monolith

Single codebase with no enforced module boundaries.

* Good, because simplest to build initially
* Good, because no deployment complexity
* Good, because easy to refactor
* Bad, because high risk of tight coupling
* Bad, because difficult to extract services later
* Bad, because code organization typically degrades over time
* Bad, because no preparation for future scaling needs

##### Modular Monolith with Clear Boundaries

Single deployment with enforced module boundaries aligned to domain boundaries.

* Good, because fast development (no distributed complexity)
* Good, because enforced boundaries prevent coupling
* Good, because modules can be extracted to services later
* Good, because simpler than microservices
* Good, because single database simplifies transactions
* Good, because easier debugging than microservices
* Bad, because requires discipline to maintain boundaries
* Bad, because entire application must be deployed together
* Bad, because shared technology stack across modules

##### Microservices from Day One

Multiple services with separate deployment and databases.

* Good, because independent deployment of services
* Good, because can scale services independently
* Good, because services can use different technology stacks
* Good, because enforces loose coupling by design
* Bad, because significant upfront complexity
* Bad, because distributed system challenges (network, consistency)
* Bad, because requires experienced team (we have limited experience)
* Bad, because operational overhead too high for 4-person team
* Bad, because slower development due to distributed complexity
* Bad, because unclear domain boundaries make service decomposition premature

##### Serverless Functions

Event-driven architecture with serverless compute.

* Good, because no infrastructure management
* Good, because automatic scaling
* Good, because pay-per-use can be cost-effective
* Bad, because cold start latency issues
* Bad, because vendor lock-in (AWS Lambda, etc.)
* Bad, because complexity of distributed event-driven system
* Bad, because local development and testing more difficult
* Bad, because team has no serverless experience
* Bad, because cost can be high at scale

#### Links

* Mitigation strategies documented in [Architecture Guidelines](../architecture/module-boundaries.md)
* Extraction path documented in [Service Extraction Playbook](../architecture/service-extraction.md)

## Example 3: Authentication Approach

### ADR-0008. Use JWT with Refresh Tokens

Date: 2024-05-20

#### Status

Accepted

#### Context and Problem Statement

Our application needs to authenticate users across web and mobile clients. We need session persistence across browser closes, secure token storage on mobile devices, ability to revoke access when needed, minimal database lookups for auth checks, and support for multiple concurrent sessions.

What authentication mechanism should we use that works equally well for web and mobile while balancing security, performance, and user experience?

#### Decision Drivers

* Need to support both web and mobile clients equally
* Mobile apps can't use httpOnly cookies effectively
* Want to minimize database roundtrips for every request
* Must support token revocation for security incidents
* Need to balance security with user experience (stay logged in)
* Must support multiple concurrent sessions per user

#### Considered Options

* Session cookies with server-side storage
* JWT tokens (access only)
* JWT with refresh token pattern
* OAuth2 with external provider only

#### Decision Outcome

Chosen option: "JWT with refresh token pattern", because it provides the best balance of security, performance, and cross-platform compatibility. Short-lived JWT access tokens (15 minutes) enable stateless validation, while long-lived refresh tokens (30 days) stored securely enable revocation and session management.

**Implementation details:**
- Access tokens: JWT, 15-minute expiration, contains user claims
- Refresh tokens: Opaque tokens, 30-day expiration, stored in database with device info
- Web: Refresh tokens in httpOnly cookies
- Mobile: Refresh tokens in secure storage (Keychain/Keystore)

#### Positive Consequences

* Access tokens can be validated without database lookup (JWT signature)
* Works identically for web and mobile clients
* Can revoke access by invalidating refresh tokens in database
* Short-lived access tokens limit damage if compromised
* Can track active sessions via refresh token table
* Supports multiple concurrent sessions per user

#### Negative Consequences

* More complex than simple session cookies
* Access tokens can't be revoked until expiration (15 minutes max)
* Requires secure storage on mobile (increases mobile implementation complexity)
* Need to implement token rotation securely
* Must handle clock skew for JWT expiration
* Slightly larger payload than session IDs

#### Pros and Cons of the Options

##### Session Cookies with Server-Side Storage

Traditional session-based authentication with server-side session store.

* Good, because simplest to implement and understand
* Good, because can revoke immediately (delete session)
* Good, because httpOnly cookies secure on web
* Good, because smaller payload than JWT
* Bad, because requires database lookup on every request
* Bad, because doesn't work well with mobile apps (cookie limitations)
* Bad, because requires sticky sessions or shared session store for load balancing
* Bad, because web-only solution, mobile needs different approach

##### JWT Tokens (Access Only)

JWT tokens with no refresh mechanism.

* Good, because stateless (no database lookup)
* Good, because works for both web and mobile
* Good, because simple to implement
* Bad, because cannot revoke until expiration
* Bad, because long expiration (security risk) vs short expiration (poor UX)
* Bad, because no way to track active sessions
* Bad, because user must re-authenticate frequently if tokens short-lived

##### JWT with Refresh Token Pattern

Short-lived JWT access tokens paired with long-lived refresh tokens.

* Good, because stateless access token validation
* Good, because can revoke via refresh token invalidation
* Good, because works identically for web and mobile
* Good, because balances security (short access tokens) with UX (long refresh tokens)
* Good, because can track active sessions
* Bad, because more complex implementation
* Bad, because requires secure storage on mobile
* Bad, because 15-minute window where compromised access token works

##### OAuth2 with External Provider Only

Delegate authentication to Google, GitHub, etc.

* Good, because no password management
* Good, because leverages existing user accounts
* Good, because offloads security responsibility
* Bad, because requires internet connectivity always
* Bad, because limited to users with external accounts
* Bad, because dependency on external service availability
* Bad, because doesn't meet requirement for independent auth system
* Bad, because still need token management for our API

#### Links

* [ADR-0009](0009-token-rotation-strategy.md) - Token rotation strategy and stolen token detection
* [ADR-0010](0010-mfa-integration.md) - Multi-factor authentication integration approach

## Example 4: API Versioning Strategy

### ADR-0012. Use URL Path Versioning for REST API

Date: 2024-07-08

#### Status

Accepted

#### Context and Problem Statement

Our REST API is currently unversioned at `/api/users`, `/api/products`, etc. We need to make breaking changes to some endpoints but can't break existing mobile clients (iOS and Android apps in the wild that auto-update slowly).

What API versioning strategy should we adopt that allows breaking changes without disrupting existing clients, while being simple for developers and compatible with our infrastructure?

#### Decision Drivers

* Have mobile clients in production that can't be forced to update
* Need to support at least 2 versions concurrently (current + previous)
* Want API version to be immediately visible in requests
* Team familiarity and simplicity are important
* Must work with existing API gateway and caching layers
* Need to monitor version usage to plan deprecations

#### Considered Options

* URL path versioning (`/api/v1/users`)
* Header-based versioning (`Accept: application/vnd.api.v1+json`)
* Query parameter versioning (`/api/users?version=1`)
* Content negotiation via media types
* No versioning, only additive changes

#### Decision Outcome

Chosen option: "URL path versioning", because the version is explicit in every request, works with all HTTP clients without special configuration, and integrates seamlessly with our API gateway and caching infrastructure. The visibility and simplicity outweigh the URL change requirement.

**Versioning rules:**
- Major versions only (v1, v2, v3) - no minor versions in URL
- Version in path immediately after `/api/`
- Breaking changes require new major version
- Non-breaking changes can be added to existing version
- Support N and N-1 versions (2 versions concurrently)
- Deprecation notices 6 months before removal

#### Positive Consequences

* Version is explicit and visible in every request
* Works with all HTTP clients without special headers
* Simple for developers to understand and test
* Can route different versions to different handlers easily
* Easy to monitor version usage via logs
* Compatible with CDN/caching layers
* Can deploy versions independently

#### Negative Consequences

* URL changes for every major version (clients must update)
* Can lead to code duplication across versions if not careful
* Version in URL can't be changed via content negotiation
* May need to maintain routing for multiple versions
* Documentation must cover multiple versions

#### Pros and Cons of the Options

##### URL Path Versioning

Version specified in the URL path: `/api/v1/users`

* Good, because version is explicit and visible in every request
* Good, because works with all HTTP clients without configuration
* Good, because simple for developers to understand
* Good, because easy to route to different handlers
* Good, because compatible with CDN and caching
* Good, because easy to monitor usage via URL logs
* Bad, because URL changes require client updates
* Bad, because can lead to code duplication if not careful

##### Header-Based Versioning

Version specified in Accept header: `Accept: application/vnd.api.v1+json`

* Good, because URL stays clean and consistent
* Good, because follows REST principles of content negotiation
* Good, because version can be changed without URL updates
* Bad, because requires custom header configuration in all clients
* Bad, because harder to test (can't just type URL in browser)
* Bad, because CDN caching more complex (must vary on Accept header)
* Bad, because version not visible in logs without header inspection
* Bad, because team less familiar with this approach

##### Query Parameter Versioning

Version in query string: `/api/users?version=1`

* Good, because easy to add version without changing base URL
* Good, because visible in logs and browser
* Good, because works with all HTTP clients
* Bad, because looks like a filter parameter, not fundamental API property
* Bad, because optional parameter can lead to default version ambiguity
* Bad, because caching complications (must consider query params)
* Bad, because unconventional and potentially confusing

##### Content Negotiation via Media Types

Use custom media types: `Accept: application/vnd.company.user.v1+json`

* Good, because follows REST content negotiation principles
* Good, because URLs remain stable
* Bad, because complex to implement and maintain
* Bad, because requires extensive client configuration
* Bad, because difficult for developers to understand and test
* Bad, because poor tool support (Swagger/OpenAPI complexity)
* Bad, because team has no experience with this approach

##### No Versioning, Only Additive Changes

Never make breaking changes, only add new fields/endpoints.

* Good, because simplest approach (no versioning infrastructure)
* Good, because clients never break
* Good, because no deprecated version maintenance
* Bad, because severely constrains API evolution
* Bad, because accumulates technical debt (can't remove mistakes)
* Bad, because eventual complexity from additive-only changes
* Bad, because some changes are inherently breaking (we need this capability)

#### Links

* Implementation guidelines in [API Versioning Guide](../api/versioning-guide.md)
* Deprecation process documented in [API Lifecycle](../api/lifecycle.md)

## What Makes These Examples Good

Each example demonstrates:

1. **Clear Context**: Explains the situation and why a decision is needed
2. **Decision Drivers**: Lists the forces influencing the decision
3. **Multiple Options**: Shows alternatives were genuinely considered
4. **Honest Consequences**: Documents both positive and negative outcomes
5. **Specific Details**: Includes concrete implementation notes where relevant
6. **Follow-up Hooks**: Identifies subsequent decisions that will be needed
7. **Success Criteria**: Defines what success looks like (when appropriate)

## Common Patterns Across Good ADRs

**Start with "why"**: Context explains the problem, not just the situation.

**Show your work**: List alternatives to prove they were considered.

**Be honest about trade-offs**: No decision is perfect. Document the downsides.

**Include enough detail**: Someone reading this in 2 years should understand the decision.

**Don't predict the future**: Focus on known constraints and drivers, not speculation.

**Link related decisions**: ADRs often build on or supersede other ADRs.
