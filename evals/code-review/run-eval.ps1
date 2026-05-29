<#
.SYNOPSIS
    Run the code-review skill's detection-quality evaluation and emit the
    Pattern A headline-score contract files consumed by the skill-eval CI
    workflow (see `evals/_docs/run-eval-contract.md`).

.DESCRIPTION
    Wraps `harness/Run-DetectionEval.ps1`, computes the Pattern A headline
    score:

        headline_score = 100 * caught_in_any / required_bug_count

    where `caught_in_any` is the count of required bugs (across all cases)
    that were matched in AT LEAST ONE trial, and `required_bug_count` is
    the total number of required bugs across all cases.

    Writes exactly two files to `-OutDir`:
      * `headline-score.json` — the summary card the dashboard charts.
      * `run-detail.json` — per-case trial summary for drill-down.

.PARAMETER OutDir
    Where to write the contract files (created if missing).

.PARAMETER Adapter
    Path to a reviewer adapter script. Defaults to
    `$env:CODE_REVIEW_ADAPTER` if set, else `adapters/smoke.ps1`.

    The smoke adapter returns canned reviews and is suitable for harness
    self-tests / CI plumbing validation only — it does NOT exercise
    `SKILL.md` so its score will NOT move when the prompt is edited. Use a
    real adapter (e.g. `adapters/copilot.ps1`) for regression-detection
    runs by setting `$env:CODE_REVIEW_ADAPTER`.

.PARAMETER Fixtures
    Fixture root. Defaults to `fixtures/detection/dev`.

.PARAMETER Trials
    Trials per case. Defaults to `$env:CODE_REVIEW_TRIALS` if set, else 1.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $OutDir,
    [string] $Adapter,
    [string] $Fixtures,
    [int] $Trials
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$skillDir = $PSScriptRoot

if (-not $Adapter) {
    $Adapter = if ($env:CODE_REVIEW_ADAPTER) { $env:CODE_REVIEW_ADAPTER }
               else { Join-Path $skillDir 'adapters' 'smoke.ps1' }
}
if (-not $Fixtures) {
    $Fixtures = Join-Path $skillDir 'fixtures' 'detection' 'dev'
}
if (-not $Trials) {
    $Trials = if ($env:CODE_REVIEW_TRIALS) { [int]$env:CODE_REVIEW_TRIALS } else { 1 }
}

$adapterName = [System.IO.Path]::GetFileNameWithoutExtension($Adapter)

$null = New-Item -ItemType Directory -Path $OutDir -Force
$OutDir = (Resolve-Path -LiteralPath $OutDir).Path

# Stage harness output into a subdir of OutDir so we don't pollute the
# contract output but keep artifacts available if the publisher wants them.
$harnessOut = Join-Path $OutDir '_harness'
$null = New-Item -ItemType Directory -Path $harnessOut -Force

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Write-ContractFiles {
    param(
        [Parameter(Mandatory)] $Headline,
        [Parameter(Mandatory)] $RunDetail
    )
    $headlinePath = Join-Path $OutDir 'headline-score.json'
    $detailPath   = Join-Path $OutDir 'run-detail.json'
    $headlineJson = [PSCustomObject]$Headline | ConvertTo-Json -Depth 30
    $detailJson   = [PSCustomObject]$RunDetail | ConvertTo-Json -Depth 50
    [System.IO.File]::WriteAllText($headlinePath, $headlineJson, $utf8NoBom)
    [System.IO.File]::WriteAllText($detailPath,   $detailJson,   $utf8NoBom)
    Write-Host "Wrote $headlinePath"
    Write-Host "Wrote $detailPath"
}

function Write-ErrorContract {
    param([string] $Message)
    $headline = [ordered]@{
        schema_version = 1
        pattern        = 'A'
        headline_score = $null
        status         = 'error'
        error          = $Message
        adapter        = $adapterName
        trials         = $Trials
    }
    $detail = [ordered]@{
        schema_version = 1
        pattern        = 'A'
        detail         = [ordered]@{ error = $Message }
    }
    Write-ContractFiles -Headline $headline -RunDetail $detail
}

# --- Run the harness -----------------------------------------------------

$harnessScript = Join-Path $skillDir 'harness' 'Run-DetectionEval.ps1'
if (-not (Test-Path -LiteralPath $harnessScript -PathType Leaf)) {
    Write-ErrorContract -Message "harness script not found at $harnessScript"
    return
}
if (-not (Test-Path -LiteralPath $Adapter -PathType Leaf)) {
    Write-ErrorContract -Message "adapter not found at $Adapter"
    return
}
if (-not (Test-Path -LiteralPath $Fixtures -PathType Container)) {
    Write-ErrorContract -Message "fixtures dir not found at $Fixtures"
    return
}

Write-Host "Running detection harness:" -ForegroundColor Cyan
Write-Host "  Adapter:  $Adapter"
Write-Host "  Fixtures: $Fixtures"
Write-Host "  Trials:   $Trials"
Write-Host "  Output:   $harnessOut"

try {
    & $harnessScript -Adapter $Adapter -Fixtures $Fixtures -Trials $Trials -OutDir $harnessOut | Out-Host
} catch {
    Write-ErrorContract -Message "harness failed: $($_.Exception.Message)"
    return
}

$summaryPath = Join-Path $harnessOut 'summary.json'
if (-not (Test-Path -LiteralPath $summaryPath -PathType Leaf)) {
    Write-ErrorContract -Message "harness did not produce summary.json"
    return
}

$summary = $null
try {
    $summary = Get-Content -LiteralPath $summaryPath -Raw -Encoding utf8 | ConvertFrom-Json
} catch {
    Write-ErrorContract -Message "could not parse summary.json: $($_.Exception.Message)"
    return
}

# --- Compute Pattern A metrics ------------------------------------------

# summary.json is an array of case-result objects:
#   { CaseId, Mode, Trials: [ { Trial, Status, ..., Score: { ..., Bugs: [{Id, Caught, Expectation, ...}] } } ] }
# or schema_error: { CaseId, Status: 'schema_error', Errors: [...] }

$caseSummaries = @()
$caughtInAny = 0
$requiredTotal = 0
$totalFpDistractor = 0
$totalFpUnmatched = 0
$optionalCaughtTotal = 0
$optionalTotal = 0
$totalTrialsRun = 0
$totalTrialsOk = 0

foreach ($case in @($summary)) {
    if ($case.PSObject.Properties.Name -contains 'Status' -and $case.Status -eq 'schema_error') {
        $caseSummaries += [ordered]@{
            case_id = $case.CaseId
            status  = 'schema_error'
            errors  = @($case.Errors)
        }
        continue
    }

    $caseTrials = @($case.Trials)
    $totalTrialsRun += $caseTrials.Count

    # caught_in_any per bug for this case
    $bugCaughtAny = @{}       # bugId -> bool
    $bugExpectation = @{}     # bugId -> 'required'|'optional'
    $caseFpDistractor = 0
    $caseFpUnmatched  = 0
    $trialSummaries = @()
    foreach ($t in $caseTrials) {
        $trialEntry = [ordered]@{
            trial      = $t.Trial
            status     = $t.Status
            error      = $(if ($t.PSObject.Properties.Name -contains 'Error') { $t.Error } else { $null })
            duration_ms = $(if ($t.PSObject.Properties.Name -contains 'DurationMs') { $t.DurationMs } else { $null })
        }
        if ($t.PSObject.Properties.Name -contains 'Score' -and $t.Score) {
            $totalTrialsOk++
            $det = $t.Score.Detection
            $caseFpDistractor += [int]$det.FPDistractor
            $caseFpUnmatched  += [int]$det.FPUnmatched
            $trialEntry['detection'] = [ordered]@{
                tp            = [int]$det.TP
                fn            = [int]$det.FN
                fp_distractor = [int]$det.FPDistractor
                fp_unmatched  = [int]$det.FPUnmatched
            }
            $trialBugs = @()
            foreach ($b in @($t.Score.Bugs)) {
                $expectation = $b.Expectation
                if (-not $bugExpectation.ContainsKey($b.Id)) {
                    $bugExpectation[$b.Id] = $expectation
                    $bugCaughtAny[$b.Id]   = $false
                }
                if ($b.Caught) { $bugCaughtAny[$b.Id] = $true }
                $trialBugs += [ordered]@{
                    id          = $b.Id
                    expectation = $expectation
                    caught      = [bool]$b.Caught
                }
            }
            $trialEntry['bugs'] = @($trialBugs | ForEach-Object { [PSCustomObject]$_ })
        }
        $trialSummaries += [PSCustomObject]$trialEntry
    }

    $caseRequired = 0
    $caseRequiredCaught = 0
    $caseOptional = 0
    $caseOptionalCaught = 0
    $caughtInAnyList = @()
    foreach ($bugId in $bugExpectation.Keys) {
        $isCaught = $bugCaughtAny[$bugId]
        $caughtInAnyList += [PSCustomObject][ordered]@{
            id          = $bugId
            expectation = $bugExpectation[$bugId]
            caught      = $isCaught
        }
        if ($bugExpectation[$bugId] -eq 'required') {
            $caseRequired++
            if ($isCaught) { $caseRequiredCaught++ }
        } else {
            $caseOptional++
            if ($isCaught) { $caseOptionalCaught++ }
        }
    }

    $caughtInAny  += $caseRequiredCaught
    $requiredTotal += $caseRequired
    $optionalCaughtTotal += $caseOptionalCaught
    $optionalTotal += $caseOptional
    $totalFpDistractor += $caseFpDistractor
    $totalFpUnmatched  += $caseFpUnmatched

    $caseSummaries += [ordered]@{
        case_id        = $case.CaseId
        mode           = $(if ($case.PSObject.Properties.Name -contains 'Mode') { $case.Mode } else { $null })
        required_count = $caseRequired
        required_caught = $caseRequiredCaught
        optional_count  = $caseOptional
        optional_caught = $caseOptionalCaught
        fp_distractor   = $caseFpDistractor
        fp_unmatched    = $caseFpUnmatched
        caught_in_any   = $caughtInAnyList
        trials          = $trialSummaries
    }
}

# --- Headline score ------------------------------------------------------

$caseCount = @($summary).Count
$fn = $requiredTotal - $caughtInAny

if ($requiredTotal -eq 0) {
    $headline = [ordered]@{
        schema_version = 1
        pattern        = 'A'
        headline_score = $null
        status         = 'error'
        error          = 'no required bugs across fixture set'
        adapter        = $adapterName
        trials         = $Trials
        metrics        = [ordered]@{
            tp = 0; fn = 0
            fp_distractor = $totalFpDistractor
            fp_unmatched  = $totalFpUnmatched
            case_count    = $caseCount
            required_bug_count = 0
        }
    }
} else {
    $score = [math]::Round((100.0 * $caughtInAny / $requiredTotal), 2)
    $headline = [ordered]@{
        schema_version = 1
        pattern        = 'A'
        headline_score = $score
        status         = 'ok'
        adapter        = $adapterName
        trials         = $Trials
        metrics        = [ordered]@{
            tp                  = $caughtInAny
            fn                  = $fn
            fp_distractor       = $totalFpDistractor
            fp_unmatched        = $totalFpUnmatched
            case_count          = $caseCount
            required_bug_count  = $requiredTotal
            optional_caught     = $optionalCaughtTotal
            optional_total      = $optionalTotal
            trials_total        = $totalTrialsRun
            trials_ok           = $totalTrialsOk
        }
    }
}

$runDetail = [ordered]@{
    schema_version = 1
    pattern        = 'A'
    detail         = [ordered]@{
        adapter = $adapterName
        trials  = $Trials
        cases   = @($caseSummaries | ForEach-Object { [PSCustomObject]$_ })
    }
}

Write-ContractFiles -Headline $headline -RunDetail $runDetail
