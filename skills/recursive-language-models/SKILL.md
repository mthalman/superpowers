---
name: recursive-language-models
description: Use when contexts exceed 100K tokens, when processing 100+ items requiring semantic analysis each, when information-dense tasks cause quality degradation within context window, or when direct processing costs are prohibitively high
---

# Recursive Language Models (RLM)

## Overview

**Treat long prompts as part of the environment, not as direct LLM input.**

Core principle: Store context externally as files, use code to filter/chunk programmatically, use Task tool for semantic operations on chunks.

## When to Use

**Symptoms that trigger RLM:**
- Context exceeds 100K tokens
- Dataset has 100+ items requiring semantic analysis each
- Information-dense tasks causing quality degradation even within context window
- "Process all these documents/entries/files"
- Task requires understanding most/all of the input
- Direct LLM processing fails (context window exceeded)
- Direct LLM processing works but costs are prohibitively high

**When NOT to use:**
- Small contexts (<50K tokens) with simple queries
- Tasks solvable with grep/regex alone
- Single-document analysis that fits in context
- Holistic understanding required (evolution tracing, cross-references, narrative threads) even if >100K

## Context Window Utilization Framework

**100K is a guideline for when to CONSIDER RLM, not a mandate to use it.**

Calculate utilization = (input_size / context_window_size)

**Decision framework:**
- **< 40% utilization**: Direct processing almost always better (plenty of headroom)
- **40-60% utilization** (fits comfortably):
  - Holistic understanding needed? → Direct processing
  - Information-dense causing degradation? → RLM
  - Independent items for classification? → RLM
- **60-75% utilization** (approaching limits):
  - Holistic understanding critical? → Direct if manageable
  - Otherwise → RLM (safer choice)
- **> 75% utilization**: RLM required (too close to limits)

**Example:**
- 120K tokens with 200K window = 60% utilization
- If task = trace evolution/connections → Direct processing (holistic needs override trigger)
- If task = classify 500 independent items → RLM (chunking works fine)

**Why utilization matters more than absolute size:**
- Same 120K input: 60% of 200K (comfortable) vs 86% of 140K (tight)
- Context capacity changes with model (Claude Sonnet 4.5: 200K)
- Headroom for prompt, reasoning, output matters

## Core Pattern

### ❌ Natural Approach (What Agents Do Without RLM)
```markdown
Given: 1000 entries to classify semantically

Agent thinks:
"I'll read all 1000 and classify them"
→ Tries to fit 60K+ tokens in one call
→ Context overflow OR massive cost
```

### ✅ RLM Approach
```markdown
Given: 1000 entries to classify semantically

Step 1: STORE externally
Write to scratchpad/context.txt

Step 2: PROBE with code
```python
# Use Bash tool
with open('scratchpad/context.txt') as f:
    entries = f.read().split('\n')
print(f"Total entries: {len(entries)}")
print("First entry:", entries[0])
```

Step 3: CHUNK strategically
```python
# 10 entries per chunk = 100 chunks
chunk_size = 10
for i in range(0, len(entries), chunk_size):
    chunk = entries[i:i+chunk_size]
    with open(f'scratchpad/chunk_{i//chunk_size}.txt', 'w') as f:
        f.write('\n'.join(chunk))
```

Step 4: RECURSIVE semantic analysis
Use Task tool for each chunk:
"Classify these 10 entries: [chunk content]"

Step 5: AGGREGATE with code
```python
# Combine results from all Task calls
results = [...]  # collected from Task responses
final_counts = aggregate(results)
```
```

## Quick Reference

| Operation | Tool | Example | When |
|-----------|------|---------|------|
| **Store context** | Write | Write to scratchpad/data.txt | Always (first step) |
| **Probe/explore** | Bash (Python) | `len(content)`, `content[:500]`, regex search | Before chunking |
| **Filter** | Bash (Python) | Regex, keyword matching, structural parsing | Reduce before semantic ops |
| **Chunk** | Bash (Python) | Split by size, delimiter, semantic boundary | Based on task complexity |
| **Semantic ops** | Task | Classification, extraction, reasoning over chunk | Per chunk analysis |
| **Simple aggregation** | Bash (Python) | Count, sum, deduplicate | Independent classifications |
| **Rolling synthesis** | Task (iterative) | Progressive theme refinement | Coherence matters, patterns emerge |
| **Final-only synthesis** | Task (single) | Batch-then-merge | Truly independent results OK |

## Implementation

### Pattern 1: Map-Reduce Over Large Dataset

```python
# STEP 1: Store
# Use Write tool to save to scratchpad/data.txt

# STEP 2: Chunk with Bash
with open('scratchpad/data.txt') as f:
    items = f.read().split('\n')

chunk_size = 20  # Adjust based on complexity AND item size
                 # Keep chunks under ~20K tokens (Read tool limit)
for i in range(0, len(items), chunk_size):
    chunk = items[i:i+chunk_size]
    with open(f'scratchpad/chunk_{i//chunk_size}.txt', 'w') as f:
        f.write('\n'.join(chunk))
    print(f"Created chunk {i//chunk_size}: {len(chunk)} items")
```

Then in your response, use Task tool for each chunk:
```markdown
I'll process chunk 0 first.

[Invoke Task with: "Classify these items semantically: <read chunk_0.txt>"]
```

After collecting all Task results, aggregate with code:
```python
# STEP 3: Aggregate
results = {
    'chunk_0': [...],
    'chunk_1': [...],
    # ... collected from Task responses
}

# Combine
final_result = combine_all(results)
```

### Pattern 2: Filter Before Processing

```python
# Use code to reduce input before semantic analysis
import re

with open('scratchpad/data.txt') as f:
    all_docs = f.read().split('\n\n---\n\n')

# Filter with regex FIRST
relevant = [doc for doc in all_docs
            if re.search(r'security|vulnerability|CVE', doc, re.IGNORECASE)]

print(f"Filtered from {len(all_docs)} to {len(relevant)} docs")

# NOW use Task on filtered set (much cheaper)
```

### Pattern 3: Rolling Synthesis (Progressive Refinement)

**Use when:** Analysis requires building understanding progressively (themes, patterns, contradictions)

**Don't use simple batch-then-merge when coherence matters:**

```python
# ❌ BATCH-THEN-MERGE: Works but risks fragmentation
all_themes = []
for chunk in chunks:
    themes_from_chunk = Task("Extract themes", chunk)
    all_themes.append(themes_from_chunk)

# Final merge can be overwhelming, duplicate themes likely
final = aggregate(all_themes)

# ✅ ROLLING SYNTHESIS: Progressive refinement
accumulated_themes = None

for i, chunk in enumerate(chunks):
    prompt = f"""
    New reviews: {chunk}

    Current themes from previous chunks: {accumulated_themes if accumulated_themes else "None yet - first chunk"}

    Tasks:
    1. Analyze new reviews for themes
    2. Map to existing themes where applicable
    3. Identify truly new themes not covered by existing
    4. Refine theme descriptions with new evidence
    5. Note contradictions or exceptions

    Output updated themes with evidence.
    """

    accumulated_themes = Task(prompt)
    # Each iteration refines understanding, not just adds to pile

# Final synthesis is lightweight (themes already coherent)
final_report = Task("Create final report from themes", accumulated_themes)
```

**Why rolling synthesis matters:**
- Prevents theme duplication (Chunk 1: "pricing concerns", Chunk 5: "cost issues" → merged during processing)
- Maintains narrative coherence (contradictions detected as they appear)
- Distributes cognitive load (each chunk builds on previous, final synthesis is light)
- Better quality (model sees patterns emerge rather than post-hoc aggregation)

**When to use rolling vs batch:**
- **Rolling**: Themes, patterns, narrative analysis, contradiction detection
- **Batch**: Independent classifications, counting, simple aggregation

### Pattern 4: Multi-Hop via Recursive Calls

```python
# STEP 1: Find candidates with code
import re
files_with_auth = [f for f in files if 'authenticate' in f.lower()]

# STEP 2: Understand each via Task
for file in files_with_auth:
    # Task: "Explain the authentication logic in this file"
    # Store findings

# STEP 3: Connect findings via Task
# Task: "Given these authentication components: [findings],
#        trace the complete flow and identify issues"
```

## Handling Read Tool Output Limits

**Read tool has a 25,000 token output limit.** If your chunk files exceed this:

### Option 1: Create smaller chunks (Recommended)

```python
# Calculate chunk size to stay under Read limits
# Rule of thumb: Keep chunks under 20K tokens for safety

# For large items (1000+ tokens each): 5-10 items per chunk
# For medium items (100-500 tokens each): 20-40 items per chunk
# For small items (<100 tokens each): 50-100 items per chunk

chunk_size = 10  # Adjust based on item size
```

### Option 2: Use Read tool offset/limit parameters

```python
# If chunk file exceeds 25K tokens, read in sections
chunk_path = 'scratchpad/chunk_0.txt'

# Read first 2000 lines
part1 = Read(chunk_path, offset=0, limit=2000)
result1 = Task("Analyze these items", part1)

# Read next 2000 lines
part2 = Read(chunk_path, offset=2000, limit=2000)
result2 = Task("Analyze these items", part2)

# Aggregate results
all_results = combine(result1, result2)
```

### Option 3: Split large chunks with Bash

```python
# If chunk is too large, split into sub-chunks with Bash
with open('scratchpad/chunk_0.txt') as f:
    content = f.read()

# Calculate split points (e.g., by delimiter)
items = content.split('\n\n')
items_per_subchunk = 20

for i in range(0, len(items), items_per_subchunk):
    subchunk = '\n\n'.join(items[i:i+items_per_subchunk])
    with open(f'scratchpad/chunk_0_part_{i//items_per_subchunk}.txt', 'w') as f:
        f.write(subchunk)

# Now read each sub-chunk (guaranteed under limit)
part = Read('scratchpad/chunk_0_part_0.txt')
```

**Best practice:** Size chunks conservatively to avoid hitting Read limits. Better to have more small chunks than fewer large chunks that exceed tool limits.

## The Iron Law: Show Your Work

**If you didn't show it, you didn't do it.**

RLM requires VISIBLE tool use at each step:
- ✅ Show Bash code execution with output
- ✅ Show chunk file creation
- ✅ Show explicit Task tool invocations
- ✅ Show aggregation code with results

**Don't:**
- ❌ Process silently and claim "I used RLM"
- ❌ Skip showing code/chunks/Task calls
- ❌ Provide final answer without intermediate steps

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I followed the RLM approach" | Show Bash code, chunks, Task calls, aggregation or you didn't follow RLM |
| "Processing was done per RLM pattern" | RLM means VISIBLE steps with tool use, not just claiming compliance |
| "RLM doesn't apply here, too small" | If task involves 50+ items with semantic ops, RLM saves cost/improves quality |
| "I can do this faster without all the steps" | Faster ≠ scalable. RLM is about handling scale, not speed on small inputs |

## Red Flags - You're NOT Using RLM If:

- No Bash code shown
- No chunk files created
- No Task tool invocations visible
- Final answer appears without intermediate steps
- Claimed "used RLM" without evidence

**If any of these apply, STOP. Use RLM properly or acknowledge you're processing directly.**

## Exploring RLM Alternatives

**Before committing to an approach, consider alternatives:**

### Common RLM Strategy Variations

1. **Uniform chunking**: Same chunk size for all content
   - When appropriate: Consistent task complexity throughout
   - When not: Mixed complexity levels (waste context on simple parts)

2. **Batch-then-merge**: Independent chunk processing + final aggregation
   - When appropriate: Truly independent items (classifications, extractions)
   - When not: Coherence matters (themes, patterns, narratives)

3. **Rolling synthesis**: Progressive refinement across chunks
   - When appropriate: Building understanding, themes, contradictions
   - When not: Simple independent classifications (overhead not worth it)

4. **Hierarchical**: Multi-level summarization
   - When appropriate: Very large corpora (millions of tokens)
   - When not: Moderate size where rolling synthesis works

5. **Direct processing**: Load all in context without chunking
   - When appropriate: Holistic understanding, cross-references, fits comfortably (<60% utilization)
   - When not: Exceeds 75% utilization or truly independent items

**Show your reasoning:** For complex tasks, briefly explain why you chose one strategy over others.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| **Process all in LLM directly** | Store externally first, use code to filter/chunk |
| **Use Task for filtering** | Use code (regex, keyword) for filtering, Task for semantic understanding |
| **Make chunks too small** | 10-50 items per chunk usually optimal (balance quality vs cost) |
| **Chunks too conservative for complex tasks** | With rolling synthesis, complex tasks can use 30-40 item chunks. Calculate: item_tokens × chunk_size + rolling_context + reasoning_space < 50% of window |
| **Make chunks too large** | If Task results degrade, reduce chunk size. CRITICAL: Chunks must stay under 25K tokens (Read tool limit) |
| **Chunks exceed Read tool limits** | Keep chunks under 20K tokens for safety. Use Read offset/limit parameters or split large chunks into sub-chunks |
| **Don't aggregate results** | Use code to combine Task outputs into final answer |
| **Use batch-then-merge for coherent analysis** | Use rolling synthesis when themes/patterns/contradictions matter |
| **Forget to save intermediates** | Write Task results to scratchpad files for later use |
| **Claim RLM without showing steps** | Must show Bash code, chunks, Task calls, aggregation |

## Cost Optimization

**Filter aggressively with code before using Task:**
```python
# ❌ Expensive: Task on all 1000 items (1000 Task calls)
for item in all_items:
    Task("Classify:", item)

# ✅ Cheap: Filter to 100 relevant, chunk into 10 groups (10 Task calls)
relevant = [item for item in all_items if keyword_filter(item)]
chunks = chunk(relevant, size=10)
for chunk in chunks:
    Task("Classify batch:", chunk)
```

**Batch similar operations:**
- Don't call Task once per item if you can batch 10-50 items per call
- Adjust batch size based on complexity (simple=50, complex=10)

**Reuse intermediate results:**
```python
# Save Task results to files for reuse
with open('scratchpad/classifications.json', 'w') as f:
    json.dump(results, f)
# If you need them again later, read from file instead of re-processing
```

## Real-World Impact

**From the RLM paper (Zhang et al., 2025):**
- Handles inputs 100x beyond model context windows
- On 6-11M token document corpus: 91% accuracy vs 0% for base model
- On information-dense tasks: 2x better performance at comparable cost
- Degrades gracefully as context grows (vs catastrophic degradation for base models)

**Key results:**
- OOLONG (semantic aggregation): 56% vs 44% accuracy
- BrowseComp-Plus (1K docs): 91% vs 0% accuracy
- OOLONG-Pairs (quadratic complexity): 58% vs 0.04% F1 score
