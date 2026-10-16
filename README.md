# Agents

Shared AI skills for **Claude Code**, **GitHub Copilot CLI**, and **OpenAI
Codex**. All three clients use the same `skills/` directory. The plugin needs no
build step; individual skills can require additional tools.

## Layout

```text
.claude-plugin\
  plugin.json          # Claude Code and Copilot CLI manifest
  marketplace.json     # Claude Code marketplace
.codex-plugin\
  plugin.json          # Codex manifest
.agents\plugins\
  marketplace.json     # Codex marketplace
skills\                # Shared skill definitions and bundled resources
agents\                # Custom agent definitions
commands\              # Client-specific commands
scripts\               # Repository maintenance and evaluation helpers
tests\                 # Regression tests
evals\                 # Skill evaluations
```

## Install

Use current client versions with plugin support. Run the local examples from
the repository root in PowerShell.

### Claude Code

Load locally for development:

```powershell
$pluginPath = (Get-Location).Path
claude --plugin-dir $pluginPath
```

For persistent installation, run these commands inside Claude Code:

```text
/plugin marketplace add mthalman/agents
/plugin install agents@agents
```

### GitHub Copilot CLI

Copilot CLI recognizes the Claude plugin manifest. Load the local checkout for
development without changing installed plugins:

```powershell
$pluginPath = (Get-Location).Path
copilot --plugin-dir $pluginPath plugin list
copilot --plugin-dir $pluginPath
```

For persistent installation from GitHub, use
`copilot plugin install mthalman/agents`.

### OpenAI Codex

Register the local marketplace, then install the plugin:

```powershell
$pluginPath = (Get-Location).Path
codex plugin marketplace add $pluginPath
codex plugin add agents@agents
codex plugin list
```

These commands require a Codex release with native plugin support.

### Existing installations

The plugin and both marketplaces now use the name `agents`. If you previously
installed `superpowers`, remove that installation through the client's plugin
manager before installing `agents`, so the same skills are not loaded twice.
Claude Code installations using the old `superpowers-dev` marketplace must
register the repository again to use `agents@agents`.

## Add a skill

Create `skills/<skill-name>/SKILL.md`. Use a lowercase, hyphen-separated name and
portable YAML frontmatter with `name` and `description`, followed by Markdown
instructions. For example, `skills/review-changes/SKILL.md`:

```markdown
---
name: review-changes
description: Review code changes for correctness, regressions, and missing tests.
---

Read the changes and relevant surrounding code. Report actionable findings with
file references and explain any checks you could not perform. Do not modify
files unless the user explicitly asks.
```

Keep shared skills client-neutral. Put optional supporting resources beside the
skill file and reference them using relative paths. Avoid client-specific tools,
hooks, or frontmatter when a skill must work across all three clients. Existing
commands and custom agents remain separate from the shared skills directory.

Keep the plugin name, version, description, and skills path aligned in both
plugin manifests. Marketplace entries point at the repository root.

## Validation

Run the focused scaffold and skill-reference checks:

```powershell
Invoke-Pester -Path tests\plugins\, tests\skills\ -Output Detailed
```

Check that both versions agree with the existing Bash helper, which requires
`jq`:

```powershell
bash scripts\bump-version.sh --check
```

To change the shared version, pass the new version to the same helper. The
catalogs do not contain version fields.

After adding skills, load or install the plugin in each client and verify that
the skills are discovered. Manifest and reference checks alone do not validate
client behavior. The evaluation toolchain under `evals/` has its own dependencies.

## Format references

- [Claude Code plugins](https://code.claude.com/docs/en/plugins)
- [Copilot CLI plugin reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference)
- [Codex plugin authoring](https://github.com/openai/skills/tree/main/skills/.system/plugin-creator)

## License

MIT License. See [LICENSE](LICENSE) for details.
