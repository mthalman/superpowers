<#
.SYNOPSIS
    Parse a code review (markdown produced by an LLM following the
    code-review skill's output format) into a structured object.

    Returns a PSCustomObject:
      {
        Parseable      : bool                       # false if it didn't look like a review at all
        Title          : string | $null             # text after the leading '## ' (e.g., 'Code Review')
        Motivation     : string | $null
        Approach       : string | $null
        SummaryLine    : string | $null             # raw verdict line text
        Verdict        : 'lgtm'|'needs_human_review'|'needs_changes'|'reject'|'review_incomplete'|'unknown'
        Findings       : Finding[]
        HasMultiModel  : bool                       # detected a 'Multi-Model' / 'Step 5' section
        MultiModelSkipDocumented : bool             # 'Multi-model review skipped: ...'
        HasGrillSection: bool
        GrillWordCount : int                        # length of content after a Grill / Step 6 heading
        RawText        : string
        ParseWarnings  : string[]
      }

    Each Finding:
      {
        Severity   : 'error'|'warning'|'suggestion'|'unknown'
        Category   : string                         # text after the icon, before the dash
        Title      : string                         # text after the dash
        Body       : string                         # paragraph text under the heading
        FileRefs   : @( @{ File=...; Line=int|null }, ... )
      }

.NOTES
    The parser is intentionally permissive. We want to extract everything
    the reviewer produced so downstream matchers can be strict; we don't
    want to reject reviews because of cosmetic formatting drift.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Verdict detection ---------------------------------------------------

function Get-VerdictFromSummary {
    [CmdletBinding()]
    param(
        [string] $SummaryLine,
        [switch] $DeclaredOutcomeOnly
    )

    if (-not $SummaryLine) { return 'unknown' }
    $text = $SummaryLine.Trim()

    # Allow callers to pass either the raw declared value or a full
    # Markdown Summary/Verdict line; in the latter case, strip the label first.
    if ($text -match '^\s*(?:[-*+]\s*)?(?:\*\*)?(?:Summary|Verdict)(?:\*\*)?\s*[:\-]\s*(?:\*\*)?\s*(.*)$') {
        $text = $matches[1].Trim()
    }

    $t = $text.ToLowerInvariant()

    # Order matters: incomplete and human-review outcomes must beat other tokens.
    if ($DeclaredOutcomeOnly) {
        $declaredPrefix = '^\s*(?:(?:✅|⚠️?|❌|⏸️?)\s+)?'
        if ($t -match "${declaredPrefix}(?:review[\s\-]?incomplete|incomplete[\s\-]?review)\b") { return 'review_incomplete' }
        if ($t -match "${declaredPrefix}reject(?:ed|ion)?\b") { return 'reject' }
        if ($t -match "${declaredPrefix}needs[\s\-]?human\b") { return 'needs_human_review' }
        if ($t -match "${declaredPrefix}needs[\s\-]?changes\b") { return 'needs_changes' }
        if ($t -match "${declaredPrefix}(?:lgtm|looks good to me|approved)\b") { return 'lgtm' }
        return 'unknown'
    }
    if ($t -match 'review[\s\-]?incomplete|incomplete[\s\-]?review') {
        return 'review_incomplete'
    }
    if ($t -match 'reject')             { return 'reject' }
    if ($t -match 'needs[\s\-]?human')  { return 'needs_human_review' }
    if ($t -match 'needs[\s\-]?changes') { return 'needs_changes' }
    if ($t -match 'lgtm|looks good to me|approved') { return 'lgtm' }
    return 'unknown'
}

# --- Severity detection from finding heading ----------------------------

function Get-SeverityFromHeading {
    [CmdletBinding()]
    param([string] $HeadingText)

    if (-not $HeadingText) { return 'unknown' }
    # Accept emoji OR textual fallback (severity icons may be stripped).
    if ($HeadingText -match '❌|:x:|\bError\b|\b\[ERROR\]') { return 'error' }
    if ($HeadingText -match '⚠️|⚠|:warning:|\bWarning\b|\b\[WARN(ING)?\]') { return 'warning' }
    if ($HeadingText -match '💡|:bulb:|\bSuggestion\b|\bNote\b|\b\[SUGGEST(ION)?\]') { return 'suggestion' }
    return 'unknown'
}

# --- File / line reference extraction -----------------------------------

# Match references like:
#   src/foo.ts:42
#   `src/foo.ts:42`
#   `src/foo.ts` line 42
#   src\foo.ts:42
#   path/to/File.cs (line 100)
$script:FileRefPatterns = @(
    # path:line in backticks   `src/foo.ts:42`  or  `src/foo.ts:42-50`
    '(?<file>[\w./\\][\w./\\\-]*\.[\w]+):(?<line>\d+)',
    # path then 'line N' / '(line N)'
    '(?<file>[\w./\\][\w./\\\-]*\.[\w]+)\s*\(?\bline[s]?\s+(?<line>\d+)\)?'
)

# Bare file (no line)
$script:BareFilePattern = '(?<file>[\w./\\][\w./\\\-]*\.[\w]+)'

function Get-FileRefs {
    [CmdletBinding()]
    param([string] $Text)

    $refs = New-Object System.Collections.Generic.List[object]
    $seen = New-Object System.Collections.Generic.HashSet[string]

    foreach ($pattern in $script:FileRefPatterns) {
        $matches = [regex]::Matches($Text, $pattern)
        foreach ($m in $matches) {
            $file = ($m.Groups['file'].Value -replace '\\', '/').Trim('`', '"', "'", '(', ')')
            $line = [int]$m.Groups['line'].Value
            $key = "${file}:${line}"
            if ($seen.Add($key)) {
                $refs.Add([PSCustomObject]@{ File = $file; Line = $line })
            }
        }
    }

    # Also collect bare files (line=null) so semantic-only matchers have something to work with.
    $bareMatches = [regex]::Matches($Text, $script:BareFilePattern)
    foreach ($m in $bareMatches) {
        $file = ($m.Groups['file'].Value -replace '\\', '/').Trim('`', '"', "'", '(', ')')
        # Skip if we already have a (file, line) for this file — line is more specific.
        if (-not ($refs | Where-Object { $_.File -eq $file -and $_.Line })) {
            $key = "${file}:"
            if ($seen.Add($key)) {
                $refs.Add([PSCustomObject]@{ File = $file; Line = $null })
            }
        }
    }

    return ,$refs.ToArray()
}

# --- Main parser --------------------------------------------------------

function ConvertFrom-ReviewMarkdown {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string] $Markdown)

    $warnings = New-Object System.Collections.Generic.List[string]
    $lines = $Markdown -split "(`r`n|`n)"
    # split returns the separators too when using a capture group — strip them
    $lines = @($lines | Where-Object { $_ -notmatch '^(?:`r`n|`n)$' })

    $title          = $null
    $motivation     = $null
    $approach       = $null
    $summaryLine    = $null
    $verdictLine    = $null
    $findings       = New-Object System.Collections.Generic.List[object]
    $hasMultiModel  = $false
    $multiModelSkipDocumented = $false
    $hasGrillSection = $false
    $grillContent   = New-Object System.Text.StringBuilder

    # State machine: walk lines, track current section + current finding-being-built.
    $section = 'preamble'
    $currentFindingHeading = $null
    $currentFindingBody    = New-Object System.Text.StringBuilder
    $inFence = $false
    $fenceChar = $null
    $fenceLength = 0
    $inHtmlComment = $false
    $inPreBlock = $false

    function _FlushFinding {
        param($Heading, $Body, $List)
        if (-not $Heading) { return }
        $bodyText = $Body.ToString().Trim()
        $headingClean = $Heading -replace '^#+\s*', ''

        # Try to split "Severity Category — Description"
        $severity = Get-SeverityFromHeading -HeadingText $headingClean
        # Strip the leading icon/severity word
        $rest = $headingClean -replace '^(?:❌|⚠️|⚠|💡|:[a-z]+:|\[(?:ERROR|WARN(?:ING)?|SUGGEST(?:ION)?)\]|Error|Warning|Suggestion|Note)\s*', ''
        $category = ''
        $titleText = $rest
        # Dash splitter: handle —, –, -, or :
        if ($rest -match '^\s*(?<cat>[^—–\-:]+?)\s*[—–\-:]\s*(?<title>.+)$') {
            $category = $matches.cat.Trim()
            $titleText = $matches.title.Trim()
        }

        $combinedForRefs = "$titleText`n$bodyText"
        $refs = Get-FileRefs -Text $combinedForRefs

        $List.Add([PSCustomObject]@{
            Severity = $severity
            Category = $category
            Title    = $titleText
            Body     = $bodyText
            FileRefs = $refs
            Heading  = $headingClean
        })
    }

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $isIndentedCode = $line -match '^(?: {4}|\t)'
        if ($inFence) {
            if ($section -eq 'findings' -and $currentFindingHeading) {
                [void]$currentFindingBody.AppendLine($line)
            }
            elseif ($section -eq 'grill') {
                [void]$grillContent.AppendLine($line)
            }
            $closingFencePattern = '^ {0,3}' + [regex]::Escape($fenceChar) + "{$fenceLength,}\s*$"
            if ($line -match $closingFencePattern) {
                $inFence = $false
                $fenceChar = $null
                $fenceLength = 0
            }
            continue
        }

        $fenceMatch = [regex]::Match($line, '^ {0,3}(?<marker>`{3,}|~{3,})(?<info>.*)$')
        if ($fenceMatch.Success) {
            $marker = $fenceMatch.Groups['marker'].Value
            $fenceChar = $marker.Substring(0, 1)
            $fenceLength = $marker.Length
            $infoString = $fenceMatch.Groups['info'].Value
            if ($fenceChar -eq '`' -and $infoString.Contains('`')) {
                $fenceChar = $null
                $fenceLength = 0
            }
            else {
                if ($section -eq 'findings' -and $currentFindingHeading) {
                    [void]$currentFindingBody.AppendLine($line)
                }
                elseif ($section -eq 'grill') {
                    [void]$grillContent.AppendLine($line)
                }

                $inFence = $true
                continue
            }
        }

        $lineStartsHtmlComment = $line -match '(?i)<!--'
        $lineEndsHtmlComment = $line -match '(?i)-->'
        $lineStartsPreBlock = $line -match '(?i)<pre\b[^>]*>'
        $lineEndsPreBlock = $line -match '(?i)</pre\s*>'

        if ($inHtmlComment -or $inPreBlock) {
            if ($section -eq 'findings' -and $currentFindingHeading) {
                [void]$currentFindingBody.AppendLine($line)
            }
            elseif ($section -eq 'grill') {
                [void]$grillContent.AppendLine($line)
            }

            if ($inHtmlComment -and $lineEndsHtmlComment) {
                $inHtmlComment = $false
            }
            if ($inPreBlock -and $lineEndsPreBlock) {
                $inPreBlock = $false
            }
            continue
        }

        if ($lineStartsHtmlComment -or $lineStartsPreBlock) {
            if ($section -eq 'findings' -and $currentFindingHeading) {
                [void]$currentFindingBody.AppendLine($line)
            }
            elseif ($section -eq 'grill') {
                [void]$grillContent.AppendLine($line)
            }

            if ($lineStartsHtmlComment -and -not $lineEndsHtmlComment) {
                $inHtmlComment = $true
            }
            if ($lineStartsPreBlock -and -not $lineEndsPreBlock) {
                $inPreBlock = $true
            }
            continue
        }

        if ($section -in @('preamble','holistic') -and -not $isIndentedCode -and $line -match '^\s*(?:[-*+]\s*)?(?:\*\*)?(Summary|Verdict)(?:\*\*)?\s*[:\-]\s*(?:\*\*)?\s*(.*)$') {
            $declaredValue = $matches[2].Trim()
            if ($matches[1] -eq 'Summary') {
                if (-not $summaryLine) { $summaryLine = $declaredValue }
            }
            else {
                if (-not $verdictLine) { $verdictLine = $declaredValue }
            }
        }

        # Detect H2 'Code Review' title
        if ($line -match '^##\s+(?:🤖\s*)?(.+?)\s*$' -and -not $title) {
            $title = $matches[1].Trim()
            continue
        }

        # Detect main sections (H3)
        if ($line -match '^###\s+(.+?)\s*$') {
            # First, flush any in-progress finding.
            if ($currentFindingHeading) {
                _FlushFinding -Heading $currentFindingHeading -Body $currentFindingBody -List $findings
                $currentFindingHeading = $null
                $currentFindingBody = New-Object System.Text.StringBuilder
            }
            $h = $matches[1].Trim()
            $hLower = $h.ToLowerInvariant()
            if     ($hLower -match 'holistic|summary|verdict')  { $section = 'holistic' }
            elseif ($hLower -match 'detailed findings|findings|issues') { $section = 'findings' }
            elseif ($hLower -match 'multi[\s\-]?model|step\s*5') {
                $section = 'multi_model'
                $hasMultiModel = $true
            }
            elseif ($hLower -match 'grill|self[\s\-]?critique|step\s*6') {
                $section = 'grill'
                $hasGrillSection = $true
            }
            elseif ($hLower -match 'independent assessment|step\s*2') { $section = 'independent' }
            elseif ($hLower -match 'pr narrative|reconcil|step\s*3')  { $section = 'reconcile' }
            else { $section = 'other' }
            continue
        }

        # Detect finding headings (H4)
        if ($section -eq 'findings' -and $line -match '^####\s+(.+?)\s*$') {
            if ($currentFindingHeading) {
                _FlushFinding -Heading $currentFindingHeading -Body $currentFindingBody -List $findings
            }
            $currentFindingHeading = $matches[1].Trim()
            $currentFindingBody = New-Object System.Text.StringBuilder
            continue
        }

        # Within findings, accumulate body
        if ($section -eq 'findings' -and $currentFindingHeading) {
            [void]$currentFindingBody.AppendLine($line)
            continue
        }

        # Within holistic / preamble, capture Motivation / Approach lines
        if ($section -in @('holistic','preamble','independent','reconcile','other')) {
            if ($line -match '^\s*\*\*Motivation\*\*\s*[:\-]\s*(.*)$') {
                $motivation = $matches[1].Trim()
                continue
            }
            if ($line -match '^\s*\*\*Approach\*\*\s*[:\-]\s*(.*)$') {
                $approach = $matches[1].Trim()
                continue
            }
        }

        # Capture grill content for word count
        if ($section -eq 'grill') {
            [void]$grillContent.AppendLine($line)
        }

        # Detect documented skip
        if ($line -match 'multi[\s\-]?model.+(skip|skipped)' -or
            $line -match '(skip|skipped).+multi[\s\-]?model') {
            $multiModelSkipDocumented = $true
        }
    }

    # Flush trailing finding
    if ($currentFindingHeading) {
        _FlushFinding -Heading $currentFindingHeading -Body $currentFindingBody -List $findings
    }

    if (-not $summaryLine) {
        $summaryLine = $verdictLine
    }
    $verdict = Get-VerdictFromSummary -SummaryLine $summaryLine -DeclaredOutcomeOnly

    $grillText = $grillContent.ToString()
    $grillWords = if ($grillText.Trim()) { ($grillText -split '\s+' | Where-Object { $_ }).Count } else { 0 }

    $parseable = ($title -or $findings.Count -gt 0 -or $verdict -ne 'unknown')
    if (-not $parseable) {
        $warnings.Add('Could not identify any review structure (no title, findings, or verdict).')
    }

    return [PSCustomObject]@{
        Parseable                 = $parseable
        Title                     = $title
        Motivation                = $motivation
        Approach                  = $approach
        SummaryLine               = $summaryLine
        Verdict                   = $verdict
        Findings                  = $findings.ToArray()
        HasMultiModel             = $hasMultiModel
        MultiModelSkipDocumented  = $multiModelSkipDocumented
        HasGrillSection           = $hasGrillSection
        GrillWordCount            = $grillWords
        RawText                   = $Markdown
        ParseWarnings             = $warnings.ToArray()
    }
}

Export-ModuleMember -Function ConvertFrom-ReviewMarkdown, Get-VerdictFromSummary, Get-SeverityFromHeading, Get-FileRefs
