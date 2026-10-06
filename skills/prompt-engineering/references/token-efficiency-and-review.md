# Token Efficiency and Prompt Review

Token-efficiency techniques, review checklist, common mistakes, and red flags for prompt audits.

## Token Efficiency

**Principle:** Precision reduces tokens more than brevity.

### Remove Filler
```
❌ "I would like you to please review the code and let me know what you think..." (17 words)
✅ "Review this code for security issues." (6 words)
```

### Use Structure
```
❌ Prose explanation (200 tokens)
✅ JSON object (50 tokens)

❌ "The function should accept a string parameter called name and return..."
✅
Parameters:
- name: string

Returns: string
```

### Leverage Examples Over Explanation
```
❌ "The output should be formatted as a JSON object with a 'summary' field containing
a brief description, an 'issues' array with objects that have 'description' and 'severity'
fields..." (30 words)

✅ "Output format:
{
  "summary": "brief description",
  "issues": [{"description": "...", "severity": "High"}]
}" (15 words + example)
```

### Avoid Redundancy
```
❌ "Check for bugs, errors, issues, or problems in the code"
✅ "Check for bugs and logical errors"
```

## Review Checklist

When reviewing prompts, check:

- [ ] **Clear task definition** - Can you restate what's being asked?
- [ ] **Specific success criteria** - What makes a good response?
- [ ] **Necessary context provided** - All required information present?
- [ ] **Output format specified** - Structure, length, style defined?
- [ ] **Edge cases addressed** - Empty/invalid/unusual inputs handled?
- [ ] **Examples included** - Demonstrated desired output (if complex)?
- [ ] **Ambiguity removed** - No terms with multiple meanings?
- [ ] **Constraints stated** - Boundaries, limitations, requirements clear?
- [ ] **Token efficiency** - No filler words or redundancy?
- [ ] **Proper structure** - Sections, delimiters, hierarchy used?
- [ ] **Model selection considered** - Right model for task?

## Common Mistakes

| Mistake | Why It's Bad | Fix |
|---------|--------------|-----|
| **Vague verbs** ("improve", "optimize") | Unclear what to optimize for | "Reduce time complexity from O(n²) to O(n log n)" |
| **Assumed context** | Model doesn't know your codebase | Provide relevant context explicitly |
| **Multiple tasks** | Dilutes focus, harder to evaluate | One clear task per prompt |
| **No output format** | Gets variable/unexpected responses | Specify JSON, markdown, bullets, etc. |
| **Overly verbose** | Wastes tokens, buries key info | Remove filler, use structure |
| **Missing examples** | Ambiguous intent | Show 1-2 examples of desired output |
| **Negative instructions** | Less effective than positive | "Do Y instead of don't do X" |
| **Undefined scope** | Endless or mismatched responses | Set clear boundaries |
| **Generic role** | Lack of expertise framing | "Security expert" not just "helpful assistant" |
| **Skipping edge cases** | Breaks on unusual input | "If empty, return X. If invalid, return Y." |

## Red Flags - Stop and Revise

If your prompt has ANY of these, revise before using:

- "Analyze this" without specifying what to analyze for
- "Make it better" without defining "better"
- No output format specified
- Vague words: "important", "relevant", "appropriate", "good"
- Multiple unrelated tasks in one prompt
- No examples for complex/novel tasks
- Assumed knowledge about your specific context
- Generic role ("helpful assistant") for specialized tasks
- No edge case handling
- Overly polite filler ("I would appreciate if you could please...")
