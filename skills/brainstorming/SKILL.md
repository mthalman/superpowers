---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
---

# Brainstorming Ideas Into Designs

## Overview

Help turn ideas into fully formed designs and specs through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design in small sections (200-300 words), checking after each section whether it looks right so far.

## The Process

**Understanding the idea:**
- Check out the current project state first (files, docs, recent commits)
- Ask questions one at a time to refine the idea
- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message - if a topic needs more exploration, break it into multiple questions
- Focus on understanding: purpose, constraints, success criteria

**Prioritize questions by impact:**
- **Ask about goals/success criteria FIRST** before diving into technical details
- Example order for vague problems:
  1. "What does success look like quantitatively?" (establishes target)
  2. "What's the highest-impact area?" (narrows scope)
  3. "What constraints exist?" (defines boundaries)
  4. Then technical: "What tools/systems are involved?"
- Example: For "make it faster" → First ask "What does 'fast' mean? 2 seconds? 20 seconds?" before asking "Do you have monitoring?"

**When you identify competing stakeholder priorities:**
- Don't just acknowledge the tension—provide navigation strategy
- Identify who has final decision authority
- Look for solutions that partially satisfy multiple parties
- Define explicit communication plans: what updates, to whom, how often
- Example: "Product VP wants speed, CTO wants sustainability. Recommend: Quick win (addresses speed) + diagnostic foundation (enables future sustainability). Update VP on user-facing improvements daily, update CTO on technical foundation weekly."

**Exploring approaches:**

⚠️ **COGNITIVE CHECKPOINT: Before presenting approaches**

For each approach you're considering, you must be able to articulate in one sentence:
- **WHY** it serves the user's stated priority/constraint
- **WHAT** specific advantage it provides for their context

If you cannot clearly articulate why an approach fits → Don't present it
If you can clearly articulate → Document the reasoning and present

- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

**Articulating trade-offs at appropriate depth:**

Match trade-off complexity to problem complexity.

**For simple, low-risk problems:**
- Simple pros/cons lists are sufficient
- Focus on time vs. features trade-offs
- Example: "Approach A is faster but less flexible. Approach B takes longer but supports future extensions."

**For complex, high-stakes problems:**
- Articulate the underlying principle creating the trade-off
- Explain HOW context determines which side to favor
- Include specific metrics, thresholds, or regulatory context
- Template:
  ```
  Trade-off: [Principle A] vs [Principle B]

  The tension: [Explain why you can't have both]

  Option 1 favors [A]:
  - Benefit: [specific outcome]
  - Cost: [what you give up]
  - Choose when: [context factors]

  Option 2 favors [B]:
  - Benefit: [specific outcome]
  - Cost: [what you give up]
  - Choose when: [context factors]

  Recommendation for this context: [Choice] because [context factor weighs more heavily]
  ```
- Example: "Trade-off: Consistency vs. Availability (CAP Theorem). For financial data with regulatory requirements, favor consistency (CP) because regulatory penalties for missed discrepancies exceed SLA breach penalties. Use circuit breakers with manual failover, not automatic degradation."

**Presenting the design:**
- Once you believe you understand what you're building, present the design
- Break it into sections of 200-300 words
- Ask after each section whether it looks right so far
- Cover: architecture, components, data flow, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

## After the Design

**Documentation:**
- Write the validated design to `docs/plans/YYYY-MM-DD-<topic>-design.md`
- Use elements-of-style:writing-clearly-and-concisely skill if available
- Commit the design document to git
- **REQUIRED:** Use superpowers:adr-generator skill to evaluate whether architectural decisions need documentation
  - The adr-generator skill will guide you through determining what's significant
  - You MUST invoke this skill before proceeding to implementation

**Implementation (if continuing):**
- Ask: "Ready to set up for implementation?"
- Use superpowers:using-git-worktrees to create isolated workspace
- Use superpowers:writing-plans to create detailed implementation plan

## Adapting to Different Contexts

The brainstorming process should scale to match your project context. Not every scenario needs the same depth of exploration.

### Question Strategy by Context

**Well-Defined Feature (clear requirements, known constraints):**
- Questions: 5-8 total, focused on refinement
- Focus: Edge cases, integration points, constraints
- Time investment: 10-20 minutes
- Example: "The feature is clear. I'll ask about integration points and edge cases..."

**Vague Problem (unclear scope, multiple interpretations):**
- Questions: 8-12 total, focused on scope narrowing
- Focus: Defining success criteria, identifying highest-impact area
- Time investment: 15-30 minutes
- Example: "This problem is broad. I'll ask questions to narrow to the most important aspect..."

**Solo Exploration / Learning Exercise:**
- Questions: 2-4 total, focused on goals
- Focus: Learning objectives, validation criteria
- Time investment: 5-10 minutes
- Example: "For rapid exploration, I'll confirm your goals and bias toward trying things..."

### Design Depth by Timeline

**Rapid Prototyping (<1 week, may discard):**
- Format: Checkpoint-based with binary decisions
- Sections: 2-3 focused on "does this work?"
- Emphasis: Fast validation, explicit pivot criteria
- Skip: Comprehensive architecture, detailed testing plans, long-term maintenance
- Example structure: "Checkpoint 1 (2 hours): Can I get one working example? Yes→continue, No→pivot"

**Sprint Development (1-4 weeks, production-bound):**
- Format: Traditional section-based design
- Sections: 4-6 covering architecture, components, data flow, error handling, testing
- Emphasis: 200-300 words per section, validation after each
- Include: Clear component boundaries, integration strategy, basic error handling

**Enterprise/Long-term Project (>1 month, high stakes):**
- Format: Comprehensive phased design
- Sections: 6-10 including architecture, integration, security, compliance, operations, phases
- Emphasis: Deep trade-off analysis, risk mitigation, operational concerns
- Include: Failure modes, disaster recovery, monitoring, compliance validation

### Signals for Context Recognition

**Indicators of "Keep It Simple":**
- Timeline: <1 week
- Phrases: "experiment", "prototype", "see if it works", "learning exercise"
- Stakes: "may discard", "concept validation"
- Adapt by: Fewer questions, checkpoint format, skip comprehensive design

**Indicators of "Standard Depth":**
- Timeline: 1-4 weeks
- Phrases: "sprint", "feature", "production"
- Stakes: Team will maintain, users will depend on it
- Adapt by: Traditional process as documented

**Indicators of "Go Deep":**
- Timeline: >1 month
- Phrases: "compliance", "enterprise", "zero tolerance", "multiple systems"
- Stakes: Regulatory requirements, high transaction volume, data integrity critical
- Adapt by: Deep trade-offs, risk analysis, comprehensive validation

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design in sections, validate each
- **Be flexible** - Go back and clarify when something doesn't make sense
