---
name: markdown-toolkit
description: Use when generating or validating GitHub Flavored Markdown structure and mechanics, including headings, links, tables, lists, code fences, anchors, templates, and markdownlint compliance. Use technical-writing instead for substantive document mode, information architecture, terminology, instructional clarity, or prose review.
compatibility: Validation helper requires Bash, Node.js with npm, and markdownlint-cli.
---

# Markdown Toolkit

## Overview

This skill supports GitHub Flavored Markdown (GFM) structure and validation. It
owns Markdown mechanics: headings, lists, tables, links, code fences, anchors,
templates, and markdownlint compliance.

Use `technical-writing` instead for substantive content organization,
terminology, instructional clarity, or prose review.

## When to Use This Skill

Use this skill for:

- **Document structure:** applying GFM templates and element structure to README,
  API, changelog, and guide content.
- **Validation:** checking Markdown syntax, broken internal links, and structural
  issues.
- **Style enforcement:** keeping repository Markdown formatting consistent.
- **Markdown review:** auditing mechanics without rewriting the prose argument.

Do not use this skill to decide document mode or rewrite substantive content.

## Workflow Decision Tree

```text
User request related to markdown?
│
├─ Generating new document
│  └─ Follow "Generating Markdown Documents"
│
├─ Validating existing document
│  └─ Follow "Validating Markdown Documents"
│
└─ Questions about markdown best practices
   └─ Open references/gfm-style-guide.md
```

## Generating Markdown Documents

1. **Identify the document type.** Common types include `README.md`, API
   documentation, changelog, user guide, and contributing guide.
2. **Open `references/gfm-style-guide.md` when you need structure templates or
   element examples.** Use the relevant common document template before writing.
   Open `references/document-generation-details.md` when you need the original
   document-type descriptions or generation principles.
3. **Generate well-structured GFM:**
   - ATX headings, one `#` title, no skipped heading levels.
   - Blank lines around headings, lists, tables, and code fences.
   - Language-tagged code fences with complete examples where possible.
   - Consistent `-` unordered lists and explicit ordered-list numbering.
   - Descriptive link text, relative paths for internal docs, valid anchors.
   - Simple tables with alignment markers when useful.
4. **Validate the generated document.** If validation fails, fix the reported
   mechanics and re-run validation.

## Validating Markdown Documents

Run the bundled validation script from the loaded skill directory:

```bash
SKILL_ROOT="<loaded markdown-toolkit directory>"
bash "$SKILL_ROOT/scripts/validate_markdown.sh" <file_or_directory>
```

For auto-fixable issues, add `--fix` after the target path.

Open `references/markdownlint-rules-and-troubleshooting.md` when validation
fails, markdownlint is unavailable, custom rules are needed, or you need the
common rule catalog and troubleshooting workflow.

For each error:

1. Understand the rule and the local formatting pattern.
2. Edit the file to comply with the rule.
3. Re-run validation.
4. Check structural issues that lint may not catch: broken `#anchor` links,
   heading hierarchy, consistent formatting, and readable spacing.

## Bundled Resources

- `scripts/validate_markdown.sh` validates Markdown using `markdownlint-cli` and
  `scripts/markdownlint-config.json`.
- `references/gfm-style-guide.md` contains GFM structure rules, examples, and
  document templates.
- `references/markdownlint-rules-and-troubleshooting.md` contains the rule
  catalog, configuration details, best practices, and failure handling.

Prerequisites for automated validation: Bash, Node.js with npm, and either a
`markdownlint` command on `PATH` or a project-local `markdownlint-cli`
dependency. Do not install a global or project dependency without user approval.
If markdownlint is unavailable, perform structural checks manually and report
that automated validation did not run.

## Non-Negotiable Rules

- Use valid GFM with balanced code fences.
- Preserve repository conventions unless the user asks to change them.
- Use the loaded skill root for helper scripts; do not assume the target
  repository contains this skill's `scripts/` directory.
- Use descriptive link text and relative internal links.
- Validate generated or modified Markdown when feasible.
- Do not turn prose-quality review into a Markdown lint report.
