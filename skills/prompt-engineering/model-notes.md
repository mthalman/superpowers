# Model-Specific Prompt Engineering Notes

## Claude (Anthropic)

### XML Tag Preferences

Claude responds particularly well to XML-style structure:

```xml
<instructions>
Your task description here
</instructions>

<examples>
Example 1: ...
Example 2: ...
</examples>

<thinking>
Work through the problem step by step
</thinking>

<answer>
Final response goes here
</answer>
```

**Why it works:** Claude's training emphasizes XML structure for clear section separation.

**When to use:**
- Complex prompts with multiple sections
- Need clear separation between instructions and context
- Want to encourage structured thinking

**Example:**
```xml
<role>
You are a security auditor specializing in web applications.
</role>

<task>
Review the authentication code below for OWASP Top 10 vulnerabilities.
</task>

<output_format>
- Vulnerability name
- Severity (Critical/High/Medium/Low)
- Line numbers affected
- Exploitation scenario
- Remediation steps
</output_format>

<code>
[Code here]
</code>
```

### Thinking Tokens & Extended Thinking

**Prefix for deeper reasoning:**
```
"Think step-by-step:" or "Let's work through this carefully:"
```

**Extended thinking mode** (when available):
- Automatically enabled for complex tasks
- Model takes more time to reason before responding
- Best for: complex analysis, multi-step problems, code architecture

**When to trigger:**
- "Analyze this thoroughly"
- "Think through all implications"
- Explicit step-by-step requests

### Model Tiers: Haiku vs Sonnet vs Opus

**Haiku (fastest, cheapest):**
- Use for: Simple structured tasks, quick lookups, straightforward transformations
- Keep prompts concise
- Works well with clear output formats
- Example tasks: Format conversion, simple extraction, basic code review

**Sonnet (balanced):**
- Use for: Most general tasks, code generation, analysis, agent work
- Good default choice
- 200K context window
- Example tasks: Writing code, debugging, system design

**Opus (most capable):**
- Use for: Complex reasoning, nuanced analysis, architectural decisions
- Best instruction following
- Handles ambiguity well
- Example tasks: Architectural review, complex refactoring, design decisions

**Prompt adjustment:**
```
Haiku: "Extract error messages from logs. Output JSON: {\"errors\": [...]}"
       (Direct, structured)

Sonnet: "Analyze error patterns in logs. Identify root causes and suggest fixes."
        (Moderate complexity)

Opus: "Analyze error patterns across multiple services, infer system-wide issues,
       propose architectural improvements to prevent recurrence."
       (Complex analysis)
```

### Context Window Optimization

**All Claude models: 200K token context window**

**For large documents:**
- No need to chunk if <150K tokens
- Place instructions BEFORE large documents
- Use XML tags to separate document from instructions

**Example:**
```xml
<instructions>
Extract all dates mentioned in the document below and categorize them.
</instructions>

<document>
[150,000 token document here]
</document>
```

## GPT-4 / GPT-3.5 (OpenAI)

### System Message Behavior

**Strong separation between system and user messages:**

```python
messages = [
    {"role": "system", "content": "You are a Python expert..."},  # Persistent behavior
    {"role": "user", "content": "Review this code..."}            # Specific task
]
```

**System message best practices:**
- Set persistent role/personality
- Define output format expectations
- Establish behavioral guidelines
- Keep under 500 tokens

**User message best practices:**
- Specific task for this interaction
- Context for this particular request
- Can override system message if needed

### Function Calling for Structured Outputs

**Instead of asking for JSON in prompt, use function definitions:**

```python
functions = [
    {
        "name": "extract_code_issues",
        "description": "Extract issues found in code review",
        "parameters": {
            "type": "object",
            "properties": {
                "issues": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "description": {"type": "string"},
                            "severity": {"type": "string", "enum": ["Critical", "High", "Medium", "Low"]},
                            "line": {"type": "integer"}
                        }
                    }
                }
            }
        }
    }
]
```

**Advantages:**
- Guaranteed valid JSON
- Type safety
- Better parsing reliability
- Clearer schema definition

### Prompting Technique Differences

**Chain-of-thought:**
```
Claude: "Think step-by-step:"
GPT-4: "Let's work through this carefully:" or "Let's approach this systematically:"
```

**Conciseness:**
```
Claude: Tends toward verbose explanations by default
        → Add "Be concise." when needed

GPT-4: More balanced by default
       → Less often needs conciseness reminder
```

### Model Tiers: GPT-4 vs GPT-3.5

**GPT-4 (Turbo):**
- Use for: Complex tasks, code generation, reasoning
- 128K context window (turbo)
- Better at following complex instructions
- More expensive

**GPT-3.5:**
- Use for: Simple tasks, quick responses, high volume
- 16K context window
- Faster and cheaper
- Good for straightforward transformations

## Gemini (Google)

### Multimodal Prompting

**Interleave text and images naturally:**

```
Analyze this architecture diagram and identify potential bottlenecks.

[Image of architecture diagram]

Focus on:
- Database connection pooling
- API rate limiting
- Caching strategies
```

**Best practices:**
- Be explicit about what to analyze in images
- Reference specific parts: "In the upper right corner..."
- Combine with text instructions for clarity

### Context Caching

**Gemini supports caching for repeated context:**

**Structure prompts to reuse common context:**
```
[CACHED: System prompt, documentation, large reference material]

[UNCACHED: Specific query that changes each time]
```

**Optimization:**
- Place static content early in prompt
- Separate changing content
- Reuse cached portions across requests
- Saves tokens and latency

### Prompting Differences

**Gemini prefers:**
- Clear markdown structure over XML
- Explicit section headers
- Numbered lists for steps

**Example:**
```markdown
# Task
Analyze the code below for performance issues.

## Focus Areas
1. Database query optimization
2. Loop efficiency
3. Memory usage

## Output Format
- Issue description
- Location (file:line)
- Suggested optimization
- Expected improvement

## Code
[code here]
```

## Open Source Models

### Template Formats

**Many open source models use specific chat templates:**

**Example (Llama-based):**
```
<|system|>
You are a helpful coding assistant.
<|user|>
Review this Python code for bugs.
<|assistant|>
```

**Check model documentation for:**
- Required template format
- Special tokens
- Role markers

### Capability Limits

**Common limitations:**
- **Smaller context windows** (2K-8K typical, some 32K-128K)
- **Weaker instruction following** (need more explicit prompts)
- **Less robust parsing** (stricter format requirements)

**Prompt adjustments:**
```
❌ For GPT-4: "Analyze this code"

✅ For open source: "Analyze this Python code. List each issue on a new line.
                     Format: [Line X] Description of issue"
```

**Techniques that help:**
- More explicit structure
- Simpler vocabulary
- Shorter prompts
- More examples (few-shot)
- Stricter format specifications

### Model-Specific Optimizations

**Llama 2/3:**
- Strong with markdown structure
- Benefits from clear role definition
- Works well with numbered steps

**Mistral:**
- Good instruction following
- Concise prompts work better
- Specify output format explicitly

**Code-specific models (CodeLlama, StarCoder):**
- Less preamble needed
- Direct code-focused prompts
- Include language in prompt: "Python:", "JavaScript:"

## General Cross-Model Tips

### Testing Across Models

If prompt needs to work on multiple models:

1. **Start with universal principles** (structure, examples, clarity)
2. **Avoid model-specific features** (XML for Claude, function calling for GPT)
3. **Test on lowest-capability target** (if it works there, likely works everywhere)
4. **Use markdown structure** (most universally supported)

### Model Selection Decision Tree

```
Need long context (>100K tokens)?
  YES → Claude (Opus/Sonnet)
  NO  ↓

Need guaranteed JSON output?
  YES → GPT-4 (function calling)
  NO  ↓

Need multimodal (text + images)?
  YES → GPT-4 Vision or Gemini
  NO  ↓

Need complex reasoning?
  YES → Claude Opus or GPT-4
  NO  ↓

Need cost-effective simple tasks?
  YES → Claude Haiku or GPT-3.5
  NO  ↓

Need on-premise/privacy?
  YES → Open source (Llama, Mistral)
  NO  → Default to Claude Sonnet (good balance)
```

### Tokenization Differences

**Different models have different tokenizers:**

**Same prompt, different token counts:**
```
Text: "Analyze this function for performance issues"

Claude: ~11 tokens
GPT-4: ~9 tokens
Llama: ~12 tokens
```

**Implications:**
- Don't optimize tokens for one model and assume it transfers
- Test token usage on your target model
- Structure often more important than word count

### Common Behavioral Quirks

**Refusal patterns:**

```
Claude: More cautious, may refuse edge cases
Fix: Provide context ("This is for security research...")

GPT-4: Stricter content policy
Fix: Rephrase to emphasize legitimate use case

Open source: Varies by model and fine-tuning
Fix: Check model card for known limitations
```

**Verbosity:**

```
Claude: Naturally verbose
Fix: Add "Be concise. Maximum 3 sentences per point."

GPT-4: Balanced
Fix: Usually doesn't need adjustment

Gemini: Can be terse
Fix: "Provide detailed explanation" if needed
```

### Format Following

**Reliability ranking (best to worst):**

1. GPT-4 with function calling (guaranteed structure)
2. Claude Opus (excellent instruction following)
3. Claude Sonnet (very good)
4. GPT-4 (very good)
5. Gemini (good)
6. Claude Haiku (good for simple structures)
7. GPT-3.5 (moderate)
8. Open source (varies, generally requires more explicit formatting)

**Recommendation:**
- If structure is critical → Use GPT-4 function calling or Claude Opus
- If structure is important → Provide explicit JSON schema in prompt
- If structure is nice-to-have → Use examples and markdown

## Model Update Frequency

**Model behaviors change with updates:**

- **Test prompts after model updates** (quarterly-ish for major providers)
- **Don't over-optimize** for current model version quirks
- **Rely on universal principles** (they survive updates)
- **Document which model version** you tested on

**Versioning in code:**
```python
# Tested with: claude-3-5-sonnet-20241022
# Tested with: gpt-4-turbo-2024-04-09
```

## The Bottom Line

**Universal principles work everywhere:**
- Clarity
- Structure
- Examples
- Explicit output formats

**Model-specific optimizations matter for:**
- Edge performance gains
- Specific capabilities (multimodal, function calling)
- Cost optimization
- Handling model quirks

**Start universal, optimize per-model only when needed.**
