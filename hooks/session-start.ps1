#!/usr/bin/env pwsh
# SessionStart hook for superpowers plugin

$ErrorActionPreference = 'Stop'

# Determine plugin root directory
$ScriptDir = Split-Path -Parent $PSCommandPath
$PluginRoot = Split-Path -Parent $ScriptDir

# Read using-superpowers content
try {
    $usingSuperpowersContent = Get-Content -Path "$PluginRoot/skills/using-superpowers/SKILL.md" -Raw -ErrorAction Stop
} catch {
    $usingSuperpowersContent = "Error reading using-superpowers skill"
}

# Escape content for JSON
$usingSuperpowersEscaped = $usingSuperpowersContent -replace '\\', '\\' -replace '"', '\"' -replace "`r`n", '\n' -replace "`n", '\n'
$warningEscaped = $warningMessage -replace '\\', '\\' -replace '"', '\"' -replace "`r`n", '\n' -replace "`n", '\n'

# Output context injection as JSON
@"
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<EXTREMELY_IMPORTANT>\nYou have superpowers.\n\n**The content below is from skills/using-superpowers/SKILL.md - your introduction to using skills:**\n\n$usingSuperpowersEscaped\n\n$warningEscaped\n</EXTREMELY_IMPORTANT>"
  }
}
"@

exit 0
