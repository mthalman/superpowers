# Prompt Structures and Patterns

Detailed structures, clarity techniques, and reusable prompt patterns for complex prompting work.

## Structural Elements

### Delimiters and Organization

**XML tags** (especially effective with Claude):
```
<instructions>
Task description here
</instructions>

<examples>
Example 1: input → output
Example 2: input → output
</examples>

<context>
Background information
</context>
```

**Markdown structure** (universal):
```
# Main Task
Brief overview

## Requirements
- Requirement 1
- Requirement 2

## Output Format
Specify exact structure here

## Examples
Show 1-2 examples
```

**Hierarchical organization:**
```
Overview (what you're asking)
  ↓
Details (specifics, constraints)
  ↓
Examples (desired output)
  ↓
Context (background info if needed)
```

### Output Format Specification

**ALWAYS specify output format.** This is the most common gap in weak prompts.

**Bad:**
```
"Review this code and tell me what's wrong"
```

**Good:**
```
"Review this code. Output format:
- Issue description
- Severity (Critical/High/Medium/Low)
- Line number
- Suggested fix"
```

**Even better with structure:**
```json
{
  "issues": [
    {
      "description": "string",
      "severity": "Critical|High|Medium|Low",
      "line": number,
      "fix": "string"
    }
  ]
}
```

## Clarity Techniques

### 1. Be Explicit About Assumptions
```
❌ "Analyze this function"
✅ "Analyze this Python function. Assume Python 3.10+. Focus on type safety and error handling."
```

### 2. Define Ambiguous Terms
```
❌ "Write clean code"
✅ "Write code following: single responsibility per function, descriptive names, <100 lines per function"
```

### 3. Specify Edge Cases
```
❌ "Parse this input"
✅ "Parse this input. If empty: return {}. If malformed: return error with specific line. If valid: return parsed object."
```

### 4. Use Positive Framing
```
❌ "Don't forget error handling"
✅ "Include error handling for: network failures, invalid input, timeout"
```

### 5. Quantify Vague Requirements
```
❌ "Brief summary"
✅ "Summary in 2-3 sentences, max 50 words"

❌ "Several examples"
✅ "3-5 examples showing common cases"
```

### 6. Separate Instructions from Context
```
<instructions>
Extract all IP references from the document below.
</instructions>

<context>
Legal documents typically reference IP in sections about licensing, warranties, and indemnification...
</context>

<document>
[Document here]
</document>
```

## Common Patterns

| Pattern | When to Use | Structure |
|---------|-------------|-----------|
| **Chain-of-thought** | Complex reasoning | "Think step-by-step: 1) Analyze X, 2) Consider Y, 3) Conclude Z" |
| **Few-shot learning** | Demonstrating format | "Example 1: input → output\nExample 2: input → output\nNow: [new input]" |
| **Role-based prompting** | Need specific expertise | "You are a [expert role] with expertise in [domain]..." |
| **Constrained generation** | Specific format required | "Output must be valid JSON matching: {schema}" |
| **Decomposition** | Multi-step tasks | "First X, then Y, finally Z. Show work for each step." |
| **Self-critique** | Quality checking | "Generate answer, review for [criteria], provide final version" |

### Pattern Examples

**Chain-of-thought:**
```
❌ Without: "Is this function optimized?"

✅ With: "Analyze this function step-by-step:
1. Identify time complexity
2. Find performance bottlenecks
3. Suggest specific optimizations
4. Estimate improvement impact"
```

**Few-shot learning:**
```
"Extract action items from meeting notes.

Example 1:
Input: 'John will send the report by Friday. Sarah needs to review before Monday.'
Output:
- [ ] John: Send report (Due: Friday)
- [ ] Sarah: Review report (Due: Monday)

Example 2:
Input: 'Team agreed to refactor auth module. Mike volunteered.'
Output:
- [ ] Mike: Refactor auth module (Due: Not specified)

Now extract from: [your text here]"
```

**Role-based:**
```
"You are a security engineer specializing in web application security with 10+ years experience in OWASP Top 10 vulnerabilities.

Review the authentication code below for security issues..."
```
