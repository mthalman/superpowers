# Prompt Engineering Quick Reference

Compact model-selection, checklist, template, and bottom-line guidance for routine prompt work.

## Model-Specific Considerations

**Universal principles above apply to all models.** Different models have specific quirks and optimizations.

**See [references/model-notes.md](model-notes.md) for detailed guidance on:**
- Claude (Sonnet/Opus/Haiku) - XML tags, thinking tokens, context handling
- GPT-4/GPT-3.5 - System messages, function calling
- Gemini - Multimodal prompting, context caching
- Open source models - Template formats, capability limits

**Quick model selection guide:**

| Task Type | Recommended Model | Why |
|-----------|------------------|-----|
| Long document analysis (100K+ tokens) | Claude Opus/Sonnet | 200K context window |
| Code generation | GPT-4, Claude Sonnet | Strong code capabilities |
| Quick simple tasks | Claude Haiku, GPT-3.5 | Cost-effective, fast |
| Multimodal (text + images) | Gemini, GPT-4 Vision | Native multimodal support |
| Structured output | GPT-4 (function calling), Claude | Strong structure following |
| Complex reasoning | Claude Opus, GPT-4 | Superior reasoning capabilities |

## Quick Reference

**When crafting any prompt, ask yourself:**

1. ❓ What exactly am I asking for? (Specific task)
2. ❓ What does good output look like? (Examples)
3. ❓ What format should the output be? (Structure)
4. ❓ What constraints apply? (Boundaries)
5. ❓ What context is needed? (Background info)
6. ❓ What edge cases exist? (Error handling)
7. ❓ Which model fits this task? (Model selection)

**Template for quick prompts:**
```
[Role]: You are a [expert type]

[Task]: [Specific action on specific target]

[Constraints]:
- [Constraint 1]
- [Constraint 2]

[Output Format]:
[Exact structure specification]

[Example]:
Input: [example input]
Output: [example output]
```

## The Bottom Line

**Effective prompts have three elements:**

1. **Specificity** - Exactly what you want, not vague requests
2. **Structure** - Clear organization and output format
3. **Examples** - Show desired output for complex tasks

**Start with these questions:**
- What exactly do I want?
- What does good output look like?
- What format should it be in?

**Then add:**
- Constraints and boundaries
- Edge case handling
- Context if needed

**Finally, remove:**
- Filler and redundancy
- Vague terms
- Unnecessary politeness

The goal: Minimal tokens for maximum clarity.
