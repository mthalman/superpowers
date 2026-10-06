# Markdownlint Rules and Troubleshooting

This reference covers validation rules, best practices, configuration, and troubleshooting for the bundled Markdown validator.

## Validation Script

**Location:** `scripts/validate_markdown.sh`

**Purpose:** Validates markdown using markdownlint-cli with GFM-specific configuration.

**Prerequisites:** Bash, Node.js with npm, and either a `markdownlint` command
on `PATH` or a project-local `markdownlint-cli` dependency.

Do not install a global or project dependency without user approval. If
markdownlint is unavailable, perform the structural checks manually and report
that automated validation did not run.

**Usage:**

```bash
SKILL_ROOT="<loaded markdown-toolkit directory>"

# Basic validation
bash "$SKILL_ROOT/scripts/validate_markdown.sh" file.md

# Auto-fix issues
bash "$SKILL_ROOT/scripts/validate_markdown.sh" file.md --fix

# Validate directory
bash "$SKILL_ROOT/scripts/validate_markdown.sh" docs/
```

**Configuration:** Rules are defined in `scripts/markdownlint-config.json`:

- Enforces ATX-style headings
- Requires consistent list markers (dashes)
- Disables line length restrictions (MD013)
- Allows specific HTML elements for GFM compatibility
- Permits duplicate headings in different sections

## Common Validation Errors

- **MD001:** Heading levels should increment by one level at a time.
- **MD003:** Heading style should be consistent. ATX style is required.
- **MD004:** Unordered list style should be consistent.
- **MD007:** Unordered list indentation should be consistent.
- **MD025:** Multiple top-level headings in the same document.
- **MD033:** Inline HTML is not allowed unless it is in the allowed list.

## Best Practices for Document Generation

1. **Start with a template:** Use structures from `references/gfm-style-guide.md`
   as starting points.
2. **Be consistent:** Apply the same formatting patterns throughout the document.
3. **Add examples:** Include code examples, usage examples, or visual examples.
4. **Link intelligently:** Use descriptive link text and relative paths for
   maintainability.
5. **Validate immediately:** Check generated documents before considering them
   complete.

## Best Practices for Validation and Style Enforcement

1. **Run validation early:** Check documents frequently during editing.
2. **Use auto-fix:** Let markdownlint fix simple formatting issues automatically.
3. **Understand the rules:** Do not fix errors blindly; learn why they matter.
4. **Be pragmatic:** Some rules can be disabled if they do not fit the project's
   needs.
5. **Document exceptions:** If disabling rules, document why in project
   documentation.

## Consistent Style Across Projects

1. **Share configuration:** Include `markdownlint-config.json` in project
   repositories when appropriate.
2. **Add to CI/CD:** Integrate markdown validation into continuous integration.
3. **Create project templates:** Build reusable templates based on the style
   guide.
4. **Review regularly:** Periodically audit documentation for consistency and
   quality.

## markdownlint-cli Not Installed

If the validation script reports that markdownlint is not found, ask before
changing dependencies. Prefer the target repository's existing dependency
policy. Common options are:

```bash
npm install --save-dev markdownlint-cli
# Or, when the user explicitly prefers a global tool:
npm install -g markdownlint-cli
```

## Validation Fails with Many Errors

For documents with numerous issues:

1. Start with auto-fix:
   `bash "$SKILL_ROOT/scripts/validate_markdown.sh" file.md --fix`
2. Address remaining errors by category: heading errors, then list errors, and
   so on.
3. Consult `references/gfm-style-guide.md` for examples of correct formatting.
4. Consider using `--fix` multiple times because some fixes enable other fixes.

## Internal Link Validation

The bundled validation script checks Markdown syntax but may not catch all
broken internal links. To verify links:

1. Check that anchor links match heading structure.
2. Remember GitHub converts headings to anchors by lowercasing, replacing spaces
   with `-`, and removing special characters.
3. Test links by viewing the rendered Markdown on GitHub when practical.

## Custom Rules Needed

To customize validation rules, edit `scripts/markdownlint-config.json`:

```jsonc
{
  "default": true,
  "MD013": false,  // Disable line length rule
  "MD041": false   // Disable "first line must be heading" rule
}
```

Refer to [markdownlint rules](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md) for all available options.
