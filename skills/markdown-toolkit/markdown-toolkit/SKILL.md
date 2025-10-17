---
name: markdown-toolkit
description: Use when generating structured markdown documents (READMEs, API docs, changelogs) or validating existing markdown for syntax errors, broken links, and style compliance. Provides GitHub Flavored Markdown (GFM) validation, comprehensive style guidelines, and document generation workflows.
---

# Markdown Toolkit

## Overview

This skill provides comprehensive support for generating and validating GitHub Flavored Markdown (GFM) documents. Use it when creating structured documentation, validating existing markdown files, or enforcing consistent style guidelines across a project.

## When to Use This Skill

Use this skill for:

- **Document Generation:** Creating READMEs, API documentation, changelogs, user guides, or technical documentation
- **Validation:** Checking markdown files for syntax errors, broken internal links, or structural issues
- **Style Enforcement:** Ensuring consistent formatting and adherence to GFM best practices
- **Documentation Review:** Auditing existing markdown for quality and compliance

## Workflow Decision Tree

```
User request related to markdown?
│
├─ Generating new document
│  └─ Follow "Generating Markdown Documents" workflow
│
├─ Validating existing document
│  └─ Follow "Validating Markdown Documents" workflow
│
└─ Questions about markdown best practices
   └─ Consult GFM Style Guide reference
```

## Generating Markdown Documents

### Step 1: Understand the Document Type

Identify what type of document is needed:

- **README.md** - Project overview, features, installation, usage
- **API Documentation** - Endpoints, parameters, examples, responses
- **Changelog** - Version history, changes, fixes
- **User Guide** - Step-by-step instructions, tutorials
- **Contributing Guide** - Contribution guidelines, code of conduct

### Step 2: Consult Style Guide for Structure

Before generating content, consult the GFM style guide for the appropriate document structure:

```
Read references/gfm-style-guide.md
```

The style guide contains:
- Document structure templates for common document types
- Best practices for headings, lists, code blocks, tables
- GFM-specific features (task lists, emoji, autolinks)
- Common mistakes to avoid

Focus on the "Common Document Templates" section for the specific document type being created.

### Step 3: Generate Well-Structured Content

Follow these principles when generating markdown:

**Headings:**
- Use ATX-style headings (`# Heading`)
- Start with single `#` for document title
- Don't skip heading levels (H1 → H2 → H3, not H1 → H3)
- Add blank lines before and after headings

**Code Blocks:**
- Always specify language for syntax highlighting
- Use ` ```language ` format
- Include complete, runnable examples where possible
- Add comments for complex code

**Lists:**
- Use `-` for unordered lists consistently
- Use 2-space indentation for nested items
- Add blank lines before and after lists
- Number ordered lists explicitly (1, 2, 3)

**Links:**
- Use descriptive link text (avoid "click here")
- Use relative paths for internal documentation
- Create anchor links for internal references
- Verify internal links match heading structure

**Tables:**
- Align pipes for readability
- Use column alignment (`:---`, `:---:`, `---:`) appropriately
- Keep tables simple; use lists for complex hierarchical data
- Add blank lines before and after tables

### Step 4: Validate Generated Document

After generating the document, always validate it:

```bash
bash scripts/validate_markdown.sh path/to/generated/file.md
```

If validation fails, review errors and regenerate with corrections.

## Validating Markdown Documents

### Step 1: Run Validation Script

Execute the bundled validation script on the target file or directory:

```bash
bash scripts/validate_markdown.sh <file_or_directory>
```

**Examples:**
```bash
# Validate single file
bash scripts/validate_markdown.sh README.md

# Validate all markdown in directory
bash scripts/validate_markdown.sh docs/

# Validate and auto-fix issues
bash scripts/validate_markdown.sh README.md --fix
```

### Step 2: Interpret Validation Results

The script uses `markdownlint-cli` with GFM-optimized rules. Common errors:

- **MD001:** Heading levels should increment by one level at a time
- **MD003:** Heading style should be consistent (ATX style required)
- **MD004:** Unordered list style should be consistent
- **MD007:** Unordered list indentation should be consistent
- **MD025:** Multiple top-level headings in the same document
- **MD033:** Inline HTML is not allowed (unless in allowed list)

### Step 3: Fix Validation Errors

For each error reported:

1. **Understand the issue:** Consult `references/gfm-style-guide.md` for the correct approach
2. **Fix the error:** Edit the file to comply with the rule
3. **Re-validate:** Run the validation script again to confirm the fix

Many issues can be auto-fixed:

```bash
bash scripts/validate_markdown.sh README.md --fix
```

### Step 4: Address Structural Issues

Beyond syntax, check for:

- **Broken internal links:** Verify all `#anchor` links point to existing headings
- **Heading hierarchy:** Ensure logical document structure without skipped levels
- **Consistency:** Use uniform formatting for similar elements
- **Readability:** Add blank lines for visual separation

## Using Bundled Resources

### Validation Script

**Location:** `scripts/validate_markdown.sh`

**Purpose:** Validates markdown using markdownlint-cli with GFM-specific configuration.

**Prerequisites:**
```bash
npm install -g markdownlint-cli
```

**Usage:**
```bash
# Basic validation
bash scripts/validate_markdown.sh file.md

# Auto-fix issues
bash scripts/validate_markdown.sh file.md --fix

# Validate directory
bash scripts/validate_markdown.sh docs/
```

**Configuration:** Rules are defined in `scripts/markdownlint-config.json`:
- Enforces ATX-style headings
- Requires consistent list markers (dashes)
- Disables line length restrictions (MD013)
- Allows specific HTML elements for GFM compatibility
- Permits duplicate headings in different sections

### GFM Style Guide

**Location:** `references/gfm-style-guide.md`

**Purpose:** Comprehensive reference for GFM best practices, common patterns, and document templates.

**When to Read:**
- Before generating new documents (for structure templates)
- When fixing validation errors (for correct syntax)
- When questions arise about markdown formatting
- For examples of tables, lists, code blocks, etc.

**Contents:**
- Document structure principles
- Detailed formatting rules for each element type
- Common document templates (README, API docs, changelog)
- GFM-specific features (task lists, emoji, mentions)
- Anti-patterns and common mistakes

**How to Use:**
```
Read references/gfm-style-guide.md
```

Then search for the relevant section (e.g., "Tables", "Code Blocks", "README.md Structure").

## Best Practices

### For Document Generation

1. **Start with a template:** Use structures from the style guide as starting points
2. **Be consistent:** Apply the same formatting patterns throughout the document
3. **Add examples:** Include code examples, usage examples, or visual examples
4. **Link intelligently:** Use descriptive link text and relative paths for maintainability
5. **Validate immediately:** Check generated documents before considering them complete

### For Validation and Style Enforcement

1. **Run validation early:** Check documents frequently during editing
2. **Use auto-fix:** Let markdownlint fix simple formatting issues automatically
3. **Understand the rules:** Don't just fix errors blindly; learn why they matter
4. **Be pragmatic:** Some rules can be disabled if they don't fit the project's needs
5. **Document exceptions:** If disabling rules, document why in project documentation

### For Consistent Style Across Projects

1. **Share configuration:** Include `markdownlint-config.json` in project repositories
2. **Add to CI/CD:** Integrate markdown validation into continuous integration pipelines
3. **Create project templates:** Build reusable document templates based on the style guide
4. **Review regularly:** Periodically audit documentation for consistency and quality

## Troubleshooting

### markdownlint-cli Not Installed

If validation script reports markdownlint is not found:

```bash
# Install globally
npm install -g markdownlint-cli

# Or install locally in project
npm install --save-dev markdownlint-cli
```

### Validation Fails with Many Errors

For documents with numerous issues:

1. Start with auto-fix: `bash scripts/validate_markdown.sh file.md --fix`
2. Address remaining errors by category (all heading errors, then list errors, etc.)
3. Consult style guide for examples of correct formatting
4. Consider using `--fix` multiple times as some fixes enable other fixes

### Internal Link Validation

The bundled validation script checks markdown syntax but may not catch all broken internal links. To verify links:

1. Check that anchor links match heading structure
2. GitHub converts headings to anchors by: lowercasing, replacing spaces with `-`, removing special characters
3. Test links by viewing the rendered markdown on GitHub

### Custom Rules Needed

To customize validation rules, edit `scripts/markdownlint-config.json`:

```json
{
  "default": true,
  "MD013": false,  // Disable line length rule
  "MD041": false   // Disable "first line must be heading" rule
}
```

Refer to [markdownlint rules](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md) for all available options.
