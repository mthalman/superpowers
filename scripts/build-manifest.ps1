<#
.SYNOPSIS
    Regenerate `data/manifest.json` on the gh-pages branch by sweeping the
    last row of every `data/<skill>/history.jsonl`.

.PARAMETER PagesDir
    Root of the gh-pages checkout (the directory containing `data/`).

.EXAMPLE
    pwsh -File scripts/build-manifest.ps1 -PagesDir _pages
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $PagesDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$pagesRoot = (Resolve-Path -LiteralPath $PagesDir -ErrorAction Stop).Path
$dataRoot = Join-Path $pagesRoot 'data'
if (-not (Test-Path -LiteralPath $dataRoot -PathType Container)) {
    # No data directory yet — emit empty manifest at the expected path.
    $null = New-Item -ItemType Directory -Path $dataRoot -Force
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Read-LastJsonlLine {
    param([string] $Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    $text = [System.IO.File]::ReadAllText($Path, $utf8NoBom)
    if (-not $text) { return $null }
    # Split, trim trailing blanks, take last non-empty line.
    $lines = @($text -split "`r?`n" | Where-Object { $_.Trim() })
    if ($lines.Count -eq 0) { return $null }
    $last = $lines[$lines.Count - 1]
    try {
        return ($last | ConvertFrom-Json)
    } catch {
        Write-Warning "Skipping unparseable last line of $Path : $($_.Exception.Message)"
        return $null
    }
}

function Get-Property {
    param($Object, [string] $Name, $Default = $null)
    if ($null -eq $Object) { return $Default }
    if ($Object.PSObject.Properties.Name -contains $Name) { return $Object.$Name }
    return $Default
}

# Find the second-last row for delta computation.
function Read-SecondLastJsonlLine {
    param([string] $Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    $text = [System.IO.File]::ReadAllText($Path, $utf8NoBom)
    if (-not $text) { return $null }
    $lines = @($text -split "`r?`n" | Where-Object { $_.Trim() })
    if ($lines.Count -lt 2) { return $null }
    $prev = $lines[$lines.Count - 2]
    try { return ($prev | ConvertFrom-Json) } catch { return $null }
}

function Get-LastNonNullPattern {
    param([string] $Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    $text = [System.IO.File]::ReadAllText($Path, $utf8NoBom)
    if (-not $text) { return $null }
    $lines = @($text -split "`r?`n" | Where-Object { $_.Trim() })
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        try {
            $obj = $lines[$i] | ConvertFrom-Json
            $p = Get-Property $obj 'pattern' $null
            if ($p) { return $p }
        } catch { continue }
    }
    return $null
}

$skillEntries = @()
$skillDirs = @(Get-ChildItem -LiteralPath $dataRoot -Directory -ErrorAction SilentlyContinue)
foreach ($dir in ($skillDirs | Sort-Object Name)) {
    $historyPath = Join-Path $dir.FullName 'history.jsonl'
    $last = Read-LastJsonlLine -Path $historyPath
    if (-not $last) { continue }
    $prev = Read-SecondLastJsonlLine -Path $historyPath
    $lastScore = Get-Property $last 'headline_score' $null
    $prevScore = Get-Property $prev 'headline_score' $null
    $delta = $null
    if ($null -ne $lastScore -and $null -ne $prevScore) {
        $delta = [math]::Round([double]$lastScore - [double]$prevScore, 2)
    }

    $runCount = 0
    if (Test-Path -LiteralPath $historyPath -PathType Leaf) {
        $text = [System.IO.File]::ReadAllText($historyPath, $utf8NoBom)
        $runCount = @($text -split "`r?`n" | Where-Object { $_.Trim() }).Count
    }

    # When the latest row is an error and has no pattern, carry forward
    # the most recent known pattern so the dashboard can still render the
    # correct chart type for the skill.
    $pattern = Get-Property $last 'pattern' $null
    if (-not $pattern) {
        $pattern = Get-LastNonNullPattern -Path $historyPath
    }

    $latest = [ordered]@{
        commit               = (Get-Property $last 'commit' $null)
        short_sha            = (Get-Property $last 'short_sha' $null)
        timestamp            = (Get-Property $last 'timestamp' $null)
        headline_score       = $lastScore
        delta_from_previous  = $delta
        status               = (Get-Property $last 'status' $null)
        adapter              = (Get-Property $last 'adapter' $null)
    }

    $skillEntries += [ordered]@{
        name      = $dir.Name
        pattern   = $pattern
        latest    = [PSCustomObject]$latest
        run_count = $runCount
    }
}

$manifest = [ordered]@{
    schema_version = 1
    generated_at   = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    skills         = @($skillEntries | ForEach-Object { [PSCustomObject]$_ })
}

$manifestJson = [PSCustomObject]$manifest | ConvertTo-Json -Depth 20
$manifestPath = Join-Path $dataRoot 'manifest.json'
[System.IO.File]::WriteAllText($manifestPath, $manifestJson, $utf8NoBom)

Write-Host "Wrote $manifestPath ($($skillEntries.Count) skill(s))"
