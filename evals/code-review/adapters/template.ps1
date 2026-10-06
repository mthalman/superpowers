<#
.SYNOPSIS
    Template for a real reviewer adapter. Copy this file, rename, and
    fill in the LLM invocation. Don't edit this template in place.

.DESCRIPTION
    Reads a JSON request from stdin, builds a prompt that incorporates
    SKILL.md, the diff, and context paths, invokes an LLM CLI / API,
    and writes the review markdown to stdout.
#>

param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# 1. Parse request
$req = [Console]::In.ReadToEnd() | ConvertFrom-Json

# 2. Load the skill being evaluated, plus its on-demand references.
# SKILL.md links to references/*.md for detail it loads only when needed;
# an LLM without file access must receive them inline.
$skillPath = Join-Path $PSScriptRoot '..' '..' '..' 'skills' 'code-review' 'SKILL.md' | Resolve-Path
$skill = Get-Content -LiteralPath $skillPath -Raw
$referencesDir = Join-Path (Split-Path -Parent $skillPath) 'references'
if (Test-Path -LiteralPath $referencesDir -PathType Container) {
    foreach ($ref in Get-ChildItem -LiteralPath $referencesDir -Filter '*.md' -File | Sort-Object Name) {
        $skill += "`n`n---`nreferences/$($ref.Name):`n" + (Get-Content -LiteralPath $ref.FullName -Raw)
    }
}

# 3. Load the diff
$diff = Get-Content -LiteralPath $req.diffPath -Raw

# 4. Load PR description if present
$prSection = ''
if ($req.prDescriptionPath) {
    $prBody = Get-Content -LiteralPath $req.prDescriptionPath -Raw
    $prSection = @"

PR description:
$prBody
---
"@
}

# 5. Build the prompt
$prompt = @"
You are reviewing a code change. Follow the skill specification below to the
letter — particularly the multi-step process and output format.

The diff to review is at: $($req.diffPath)
Surrounding source files are under: $($req.contextDir)

You may read any file under contextDir to understand the change in context.

---
SKILL.md (followed by the reference files it links to):
$skill
---
$prSection
Diff content (also at the file above):

$diff
"@

# 6. Invoke the LLM
$sw = [System.Diagnostics.Stopwatch]::StartNew()

# === REPLACE THIS BLOCK WITH YOUR LLM CALL ===
# Examples:
#   $review = & 'gh' 'copilot' 'explain' --stdin -- @($prompt) 2>$null
#   $review = & 'claude' --print --prompt $prompt
#   $review = Invoke-RestMethod -Uri 'https://api.example.com/chat' -Method POST -Body $body -Headers $headers
$review = "## 🤖 Code Review`n`n**Summary**: ⚠️ Needs Human Review — template adapter, replace me.`n`n### Detailed Findings`n"
# === END LLM CALL ===

$sw.Stop()

# 7. Emit review and metadata
[Console]::Out.Write($review)
$meta = @{
    latency_ms = $sw.ElapsedMilliseconds
    model      = 'TODO'
    # tokens_in  = ?
    # tokens_out = ?
    # tool_calls = ?
} | ConvertTo-Json -Compress
[Console]::Error.WriteLine("META: $meta")

exit 0
