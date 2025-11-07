# Extension Type Classification Criteria

This document provides comprehensive criteria for classifying Claude Code extensions as commands, skills, or agents.

## Extension Type Definitions

### Commands (Slash Commands)

**Definition:** User-invoked prompts stored as Markdown files that allow defining frequently-used instructions Claude Code can execute.

**Key Characteristics:**
- **Invocation:** User explicitly types `/command-name` to trigger
- **Structure:** Single Markdown file with optional frontmatter
- **Complexity:** Simple prompts and frequently-used instructions
- **Context:** Shares the main conversation context
- **Discovery:** Manual - user must know and type the command
- **Control:** Explicit - user decides exactly when to execute

**Storage Locations:**
- Project: `.claude/commands/` (shared with team, git-tracked)
- Personal: `~/.claude/commands/` (available across all projects)

**Ideal Use Cases:**
- Quick, frequently-used prompts users manually invoke
- Simple prompt snippets that fit in a single file
- Explicit control over when execution occurs
- Team-shared templates organized by project

**Examples:**
- `/commit` - Create git commits with conventional commit messages
- `/review` - Perform code quality checks
- `/optimize` - Analyze performance
- `/explain` - Clarify code functionality
- `/test` - Run the test suite and report results

### Skills (Agent Skills)

**Definition:** Modular capabilities that extend Claude's functionality through organized folders containing instructions, scripts, and resources. Claude autonomously decides when to use them based on context.

**Key Characteristics:**
- **Invocation:** Model-invoked - Claude automatically detects when to use based on description and context
- **Structure:** Directory with `SKILL.md` + optional resources (scripts, references, assets)
- **Complexity:** Complex workflows with multi-step guidance
- **Context:** Shares the main conversation context
- **Discovery:** Automatic - Claude reads descriptions and activates when relevant
- **Control:** Implicit - Claude decides when to apply the skill

**Storage Locations:**
- Personal: `~/.claude/skills/` (individual workflows)
- Project: `.claude/skills/` (team-shared, git-tracked)
- Plugin: Bundled with installed plugins

**Ideal Use Cases:**
- Complex workflows requiring structured guidance
- Multi-phase methodologies (TDD, debugging, brainstorming)
- Domain expertise and specialized knowledge
- Workflows that should activate automatically when relevant
- Bundled resources (scripts, templates, documentation)

**Examples:**
- Systematic debugging using hypothesis-driven investigation
- Test-driven development workflow (write test, fail, implement, pass)
- Brainstorming sessions using Socratic method
- Architecture design and review processes
- Security vulnerability scanning before deployment

### Agents (Subagents)

**Definition:** Pre-configured AI personalities that Claude Code can delegate tasks to. Each operates with its own context window, custom system prompt, and configurable tool access.

**Key Characteristics:**
- **Invocation:** Delegated by main Claude instance to specialized agent
- **Structure:** Markdown file with frontmatter (name, description, tools, model) + custom system prompt
- **Complexity:** Specialized expertise requiring focused analysis
- **Context:** Independent context window (prevents main conversation pollution)
- **Discovery:** Main Claude delegates based on agent description
- **Control:** Delegation - main Claude sends tasks to agent, receives results back

**Storage Locations:**
- Project: `.claude/agents/` (shared with team)
- Personal: `~/.claude/agents/` (available across projects)
- Plugin: Bundled with installed plugins

**Ideal Use Cases:**
- Tasks requiring specialized expertise (security, performance, architecture)
- Deep analysis that would pollute main conversation context
- Operations needing restricted tool access for security
- Repeatable, focused responsibilities across projects
- Expert review and validation workflows

**Examples:**
- Code reviewer analyzing implementations against plans
- Security auditor performing vulnerability assessments
- Database query optimizer profiling and suggesting improvements
- Performance analyzer identifying bottlenecks
- API designer creating specifications

## Decision Framework

### Decision Tree

Use this flowchart to classify extensions:

```
START: What is the functionality?
│
├─ Does user explicitly invoke with /command?
│  └─ YES → Is it a simple, single-purpose prompt?
│     ├─ YES → COMMAND
│     └─ NO → Might be SKILL (if complex workflow)
│
├─ Does this need independent context window?
│  └─ YES → Does it require specialized expertise?
│     ├─ YES → AGENT
│     └─ NO → SKILL (unless explicitly invoked)
│
├─ Is this a complex multi-step workflow?
│  └─ YES → Should it auto-activate or be manually invoked?
│     ├─ Auto-activate → SKILL
│     └─ Manual → COMMAND
│
└─ Is this a simple, frequent prompt?
   └─ YES → COMMAND
```

### Key Differentiators

| Aspect | Command | Skill | Agent |
|--------|---------|-------|-------|
| **Invocation** | User types `/cmd` | Claude auto-detects | Claude delegates |
| **Complexity** | Simple prompt | Complex workflow | Specialized expertise |
| **Structure** | Single .md file | Directory + resources | .md with config + prompt |
| **Context** | Shared | Shared | Independent |
| **Discovery** | Manual | Automatic | Automatic (delegation) |
| **Tool Access** | All tools | All tools (configurable) | Restricted (configurable) |
| **Files** | One only | Multiple allowed | One config file |
| **Best For** | Quick prompts | Methodologies | Expert analysis |

## Validated Example Classifications

### Commands

1. **"Create well-formatted git commits with conventional commit messages"**
   - **Why Command:** User explicitly invokes when ready to commit, simple prompt, frequently used

2. **"Run the test suite and report results"**
   - **Why Command:** Simple one-off task, explicit invocation, no complex workflow

3. **"Explain this code snippet in simple terms"**
   - **Why Command:** Quick prompt for clarification, user-initiated on specific code

4. **"Generate API documentation from code comments"**
   - **Why Command:** Specific task triggered manually, straightforward execution

### Skills

5. **"Guide systematic debugging using hypothesis-driven investigation before proposing fixes"**
   - **Why Skill:** Complex multi-phase workflow, should auto-activate when bugs encountered, provides structured methodology

6. **"Apply test-driven development by writing tests first, watching them fail, then implementing minimal code to pass"**
   - **Why Skill:** Multi-step methodology, should auto-activate during implementation, shares context with main conversation

7. **"Orchestrate brainstorming sessions using Socratic method to refine rough ideas into designs"**
   - **Why Skill:** Complex interactive workflow, auto-activates when design needed, structured guidance

8. **"Manage git worktrees for isolated feature development"**
   - **Why Skill:** Multi-step process with decision points, auto-activates when isolation needed, includes setup/verification

### Agents

9. **"Specialized code reviewer that analyzes implementations against plans and coding standards"**
   - **Why Agent:** Specialized expertise, needs independent context for deep analysis, focused responsibility

10. **"Database query optimizer that profiles slow queries and suggests index improvements"**
    - **Why Agent:** Specialized database expertise, deep analysis, may need restricted tool access

11. **"Security auditor that performs vulnerability assessments before production deployments"**
    - **Why Agent:** Specialized security expertise, independent analysis, controlled tool access for safety

12. **"Performance profiler that identifies bottlenecks and recommends optimizations"**
    - **Why Agent:** Specialized performance expertise, deep analysis without polluting main conversation

## Edge Cases and Ambiguities

### Command vs Skill Ambiguities

**Scenario:** "Help me write git commit messages"

**Could be either:**
- **Command:** `/commit` - User types when ready, explicit control
- **Skill:** Auto-activates when committing detected, provides guidance

**Decision factors:**
- Team preference (explicit vs automatic)
- Complexity (simple prompt vs workflow guidance)
- Frequency (occasional vs every commit)

**Resolution:** Ask user: "Should this be manually invoked or auto-activate?"

### Skill vs Agent Ambiguities

**Scenario:** "Review code for best practices"

**Could be either:**
- **Skill:** Lightweight review guidance in main context
- **Agent:** Deep specialized review in separate context

**Decision factors:**
- Depth of analysis (quick check vs thorough review)
- Context pollution (minor feedback vs extensive comments)
- Specialization (general vs expert domain knowledge)

**Resolution:** Ask user: "Does this need deep specialized analysis or quick guidance?"

### Multiple Valid Classifications

**Scenario:** "Write implementation plans with detailed tasks"

**Could legitimately be:**
- **Command:** `/plan` - User explicitly requests when ready to plan
- **Skill:** Auto-activates when planning needed during design phase

**Both valid because:**
- User preference varies by team
- Context determines appropriateness (explicit request vs automatic)
- No wrong answer if team workflow supports it

**Resolution:** Consider team patterns and user preference

## Common Mistakes to Avoid

### Mistake 1: Classifying by Complexity Alone

**Wrong:** "This is complex, so it must be an agent"
**Right:** Consider invocation, context, and specialization together

**Example:** Complex debugging workflow is a **Skill** (auto-activates, shared context), not Agent

### Mistake 2: Ignoring Invocation Pattern

**Wrong:** "This is frequently used, so it's a command"
**Right:** Consider whether user should explicitly invoke or Claude should auto-activate

**Example:** Frequent code reviews could be **Agent** (delegated) or **Skill** (auto-activate), not Command

### Mistake 3: Confusing Tool Access with Type

**Wrong:** "This needs restricted tools, so it must be an agent"
**Right:** Tool restrictions are a configuration option, not a type determinant

**Example:** Skills can have restricted tools too; agents are distinguished by independent context

### Mistake 4: Overlooking Context Needs

**Wrong:** "This is specialized, so it's a skill"
**Right:** If deep analysis pollutes main context, it should be an **Agent**

**Example:** Extensive security audits with detailed findings → Agent (keeps main context clean)

## Quick Decision Checklist

When classifying, ask these questions:

1. **Invocation**
   - [ ] Does user type `/command` explicitly? → Command likely
   - [ ] Should Claude auto-detect and activate? → Skill likely
   - [ ] Should Claude delegate to specialist? → Agent likely

2. **Complexity**
   - [ ] Simple single-purpose prompt? → Command likely
   - [ ] Multi-step workflow with guidance? → Skill likely
   - [ ] Deep specialized expertise? → Agent likely

3. **Context**
   - [ ] Shares main conversation context? → Command or Skill
   - [ ] Needs independent context window? → Agent

4. **Structure**
   - [ ] Single file sufficient? → Command or Agent
   - [ ] Needs bundled resources? → Skill

5. **Discovery**
   - [ ] User must know to invoke? → Command
   - [ ] Claude should find automatically? → Skill or Agent

## Summary Guidelines

**Choose Command when:**
- User explicitly invokes with `/command`
- Simple, frequently-used prompt
- Single file is sufficient
- Explicit control desired

**Choose Skill when:**
- Claude should auto-activate based on context
- Complex multi-step workflow
- Needs bundled resources (scripts, templates, docs)
- Shares main conversation context

**Choose Agent when:**
- Needs independent context window
- Requires specialized expertise
- Deep analysis would pollute main context
- Tool access should be restricted
- Focused, repeatable responsibility

**When in doubt:**
- Ask clarifying questions about invocation, complexity, and context needs
- Consider team workflow preferences
- Remember some functionality can legitimately be multiple types
