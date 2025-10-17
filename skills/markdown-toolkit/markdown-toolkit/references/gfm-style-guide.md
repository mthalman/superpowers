# GitHub Flavored Markdown (GFM) Style Guide

This reference provides comprehensive guidelines for writing high-quality GitHub Flavored Markdown documents.

## Table of Contents

- [Document Structure](#document-structure)
- [Headings](#headings)
- [Lists](#lists)
- [Code and Syntax Highlighting](#code-and-syntax-highlighting)
- [Tables](#tables)
- [Links and References](#links-and-references)
- [Images](#images)
- [Emphasis and Strong](#emphasis-and-strong)
- [Blockquotes](#blockquotes)
- [Task Lists](#task-lists)
- [Common Document Templates](#common-document-templates)

## Document Structure

### General Principles

- Start with a top-level heading (single #) as the document title
- Use blank lines to separate sections for readability
- Follow a logical hierarchy without skipping heading levels
- Place table of contents after the main title for longer documents

### File Naming

- Use lowercase with hyphens: `user-guide.md`, `api-reference.md`
- Be descriptive but concise
- Avoid special characters

## Headings

### Best Practices

```markdown
# Document Title (H1 - use once per document)

Brief introduction or overview.

## Main Section (H2)

Content for main section.

### Subsection (H3)

Content for subsection.

#### Minor Section (H4)

Use H4-H6 sparingly.
```

### Rules

- Use ATX-style headings (`# Heading`) not Setext-style
- Always include a space after the `#` symbols
- Don't skip heading levels (e.g., don't jump from H2 to H4)
- Add blank line before and after headings
- Use sentence case or title case consistently

### Anti-patterns

```markdown
❌ #No space after hash
❌  # Leading whitespace
❌ ## Section
   Content without blank line

✅ # Proper heading

✅ Content with proper spacing
```

## Lists

### Unordered Lists

```markdown
- Use hyphens for consistency
- Indent nested items with 2 spaces
  - Like this nested item
  - And this one
- Back to top level
```

### Ordered Lists

```markdown
1. Use actual numbers (1, 2, 3) for clarity
2. Or use all 1s if order may change
3. Indent nested items with 3 spaces
   1. Nested numbered item
   2. Another nested item
4. Continue at top level
```

### Rules

- Use consistent markers (prefer `-` for unordered)
- Use 2-space indentation for nested items (4 spaces also acceptable)
- Add blank line before and after lists
- Use blank lines between list items if they're multi-paragraph

### Multi-paragraph List Items

```markdown
- First item with multiple paragraphs.

  Second paragraph of first item. Indented to align with first line.

- Second item also with multiple paragraphs.

  Another paragraph here.
```

## Code and Syntax Highlighting

### Inline Code

```markdown
Use `inline code` for commands, variables, and short code snippets.

Examples:
- Run the `npm install` command
- Set the `DEBUG` environment variable
- The function returns `true` or `false`
```

### Code Blocks

Always specify the language for syntax highlighting:

````markdown
```javascript
function hello() {
  console.log("Hello, world!");
}
```

```python
def hello():
    print("Hello, world!")
```

```bash
echo "Hello, world!"
```
````

### Supported Languages

Common language identifiers:
- `javascript`, `js`, `typescript`, `ts`
- `python`, `py`
- `bash`, `sh`, `shell`
- `json`, `yaml`, `xml`
- `markdown`, `md`
- `sql`, `css`, `html`
- `java`, `c`, `cpp`, `csharp`, `go`, `rust`

### Code Block Best Practices

- Always specify language (don't use plain ``` without language)
- Use descriptive variable names even in examples
- Include comments for complex examples
- Show complete, runnable examples when possible

## Tables

### Basic Table Format

```markdown
| Header 1 | Header 2 | Header 3 |
|----------|----------|----------|
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |
```

### Column Alignment

```markdown
| Left aligned | Center aligned | Right aligned |
|:-------------|:--------------:|--------------:|
| Left         | Center         | Right         |
| Text         | Text           | Text          |
```

### Best Practices

- Align pipes for readability (though not required)
- Use alignment for numeric or special data
- Keep tables simple - consider lists for complex data
- Add blank lines before and after tables

### When Not to Use Tables

- For simple key-value pairs (use description lists or bold labels)
- For very wide data (consider linking to CSV or external source)
- For deeply nested information (use headings and lists instead)

## Links and References

### Inline Links

```markdown
Visit [GitHub](https://github.com) for more info.

Link to [another section](#section-name) in this document.
```

### Reference-style Links

For repeated or long URLs:

```markdown
Check out [GitHub][gh] and [GitLab][gl] for version control.

[gh]: https://github.com
[gl]: https://gitlab.com
```

### Internal Links

```markdown
Jump to [Installation](#installation) section.

Link to [Subsection](#main-section-subsection) works too.
```

### Best Practices

- Use descriptive link text (avoid "click here")
- Verify internal links match actual heading anchors
- Use reference-style for repeated URLs
- Use relative paths for linking to other files in repo

### Link Formatting Rules

```markdown
❌ [Bad link] (https://example.com) - space before URL
❌ [Bad link](example.com) - missing protocol
❌ Click [here](https://example.com) - non-descriptive text

✅ [Good descriptive link](https://example.com)
✅ See the [installation guide](./docs/install.md)
✅ Jump to [Configuration](#configuration)
```

## Images

### Basic Syntax

```markdown
![Alt text](path/to/image.png)

![Alt text](path/to/image.png "Optional title")
```

### Best Practices

- Always include descriptive alt text for accessibility
- Use relative paths for images in the repository
- Specify dimensions in HTML if needed for layout
- Consider using reference-style for repeated images

### With HTML for Sizing

```markdown
<img src="logo.png" alt="Company Logo" width="200">
```

## Emphasis and Strong

### Basic Usage

```markdown
Use *italic* or _italic_ for emphasis.

Use **bold** or __bold__ for strong emphasis.

Use ***bold italic*** for both.
```

### Best Practices

- Use asterisks (`*`) for consistency
- Don't overuse emphasis - it loses impact
- Use bold for UI elements, commands, or important warnings
- Use italic for terms, book titles, or subtle emphasis

```markdown
Click the **Save** button to continue.

The term *recursion* refers to...

**Warning:** This action cannot be undone.
```

## Blockquotes

### Basic Syntax

```markdown
> This is a blockquote.
> It can span multiple lines.

> You can also have multiple paragraphs.
>
> Just use a blank line with `>` between them.
```

### Nested Blockquotes

```markdown
> First level
>
> > Nested quote
> >
> > > Deeply nested
```

### Best Practices

- Use for quotations, notes, or callouts
- Add blank lines before and after blockquotes
- Consider using HTML `<details>` for collapsible sections instead

## Task Lists

GFM supports interactive checkboxes:

```markdown
- [x] Completed task
- [ ] Incomplete task
- [ ] Another task
  - [x] Nested completed task
  - [ ] Nested incomplete task
```

### Best Practices

- Use for TODO lists, checklists, or progress tracking
- Works great in issues and pull requests
- Can be checked/unchecked in GitHub UI

## Common Document Templates

### README.md Structure

```markdown
# Project Name

Brief description of what the project does.

## Features

- Feature 1
- Feature 2
- Feature 3

## Installation

```bash
npm install project-name
```

## Usage

```javascript
const project = require('project-name');
```

## API Reference

### `functionName(param)`

Description of function.

## Contributing

Guidelines for contributing.

## License

MIT License
```

### API Documentation Structure

```markdown
# API Documentation

## Overview

Brief description of the API.

## Authentication

How to authenticate requests.

## Endpoints

### GET /api/resource

Description of endpoint.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| id | string | Resource ID |

**Response:**

```json
{
  "status": "success",
  "data": {}
}
```

**Example:**

```bash
curl https://api.example.com/resource?id=123
```
```

### Changelog Structure

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- New features coming soon

## [1.0.0] - 2024-01-15

### Added
- Initial release
- Feature X
- Feature Y

### Changed
- Improved performance

### Fixed
- Bug fix for issue #123
```

## GFM-Specific Features

### Autolinks

URLs and emails become clickable automatically:

```markdown
https://github.com
user@example.com
```

### Strikethrough

```markdown
~~This text is struck through~~
```

### Emoji (GitHub)

```markdown
:smile: :rocket: :heart:

Or use Unicode: 😄 🚀 ❤️
```

### Username Mentions (GitHub)

```markdown
@username will notify that user
```

### Issue/PR References (GitHub)

```markdown
#123 links to issue or PR #123
GH-123 also works
username/repo#123 for other repos
```

### Footnotes

```markdown
Here's a sentence with a footnote[^1].

[^1]: This is the footnote content.
```

## Common Mistakes to Avoid

### Don't Mix Styles

```markdown
❌ Mix of * and - in same list
* Item 1
- Item 2

✅ Consistent markers
- Item 1
- Item 2
```

### Don't Skip Blank Lines

```markdown
❌ No separation
## Heading
Content immediately after

✅ Proper spacing
## Heading

Content with blank line
```

### Don't Use Raw HTML Unless Necessary

```markdown
❌ <b>bold</b> when **bold** works
❌ <a href="url">link</a> when [link](url) works

✅ Use markdown syntax when possible
✅ Use HTML only for complex layouts or unsupported features
```

## Validation and Linting

Use `markdownlint` to enforce these guidelines:

```bash
markdownlint README.md
markdownlint --fix README.md  # Auto-fix issues
```

Common markdownlint rules:
- MD001: Heading levels increment by one
- MD003: Heading style (ATX vs Setext)
- MD004: Unordered list style
- MD007: Unordered list indentation
- MD013: Line length (often disabled for flexibility)
- MD025: Single H1 per document
- MD033: Inline HTML usage

## Additional Resources

- [GitHub Flavored Markdown Spec](https://github.github.com/gfm/)
- [CommonMark Spec](https://spec.commonmark.org/)
- [Markdown Guide](https://www.markdownguide.org/)
