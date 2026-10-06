# Markdown Document Generation Details

This reference covers document-type selection details and generation principles
from the original Markdown Toolkit guidance.

## Document Types

Identify what type of document is needed:

- `README.md` - project overview, features, installation, usage.
- API documentation - endpoints, parameters, examples, responses.
- Changelog - version history, changes, fixes.
- User guide - step-by-step instructions, tutorials.
- Contributing guide - contribution guidelines, code of conduct.

## Style Guide Lookup

Before generating content, consult the GFM style guide for the appropriate
document structure:

- document structure templates for common document types;
- best practices for headings, lists, code blocks, tables;
- GFM-specific features (task lists, emoji, autolinks).

Focus on the "Common Document Templates" section for the specific document type
being created.

## Generation Principles

Follow these principles when generating Markdown:

- Don't skip heading levels (H1 → H2 → H3, not H1 → H3).
- Add blank lines before and after headings.
- Always specify language for syntax highlighting.
- Include complete, runnable examples where possible.
- Number ordered lists explicitly (1, 2, 3).
- Use relative paths for internal documentation.
- Create anchor links for internal references.
- Verify internal links match heading structure.
- Use column alignment (`:---`, `:---:`, `---:`) appropriately.
- Keep tables simple; use lists for complex hierarchical data.
