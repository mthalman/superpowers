[CmdletBinding()]
param(
    [string] $RepoRoot,
    [string] $BaseRef = 'HEAD^',
    [string] $HeadRef = 'HEAD',
    [switch] $FullSweep,
    [string[]] $OnlySkills
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $RepoRoot = (& git rev-parse --show-toplevel).Trim()
}

function Get-EvaluatedSkills {
    Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'evals') -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName 'eval.yaml') -PathType Leaf } |
        Select-Object -ExpandProperty Name |
        Sort-Object
}

$evaluated = @(Get-EvaluatedSkills)
$selected = if ($FullSweep -or $BaseRef -eq '--full-sweep') {
    $evaluated
}
else {
    & git -C $RepoRoot rev-parse --verify "$BaseRef^{commit}" 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        $changed = @('evals/_vally/')
    }
    else {
        $changed = @(& git -C $RepoRoot diff --name-only $BaseRef $HeadRef)
        if ($LASTEXITCODE -ne 0) {
            throw "git diff failed for '$BaseRef..$HeadRef'."
        }
    }
    $sharedChanged = @($changed | Where-Object {
        $_ -match '^(evals/_vally/|\.vally\.yaml$|\.github/workflows/skill-eval\.yml$)'
    }).Count -gt 0

    if ($sharedChanged) {
        $evaluated
    }
    else {
        $names = foreach ($path in $changed) {
            if ($path -match '^(?:skills|evals)/([^/]+)/') {
                $Matches[1]
            }
        }
        @($names | Sort-Object -Unique | Where-Object { $_ -in $evaluated })
    }
}

if ($OnlySkills) {
    $allow = @($OnlySkills | ForEach-Object { $_ -split ',' } |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ })
    $selected = @($selected | Where-Object { $_ -in $allow })
}

ConvertTo-Json @($selected) -Compress
