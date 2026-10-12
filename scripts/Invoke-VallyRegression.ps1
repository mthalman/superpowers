[CmdletBinding()]
param(
    [string] $NodePath,
    [string] $VallyCliPath,
    [string] $GraderPluginPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$env:VALLY_TELEMETRY_OPTOUT = '1'

$trajectoryFiles = @(
    Get-ChildItem -Path 'evals' -Filter '*.jsonl' -Recurse -File |
        Where-Object { $_.FullName -match '[\\/]trajectories[\\/]' }
)
if ($trajectoryFiles.Count -eq 0) {
    Write-Host 'No stored trajectories are checked in yet; skipping offline re-grade.'
    return
}

$repoRoot = (& git rev-parse --show-toplevel).Trim()
if (-not $NodePath) {
    $NodePath = (Get-Command node -ErrorAction Stop).Source
}
if (-not $VallyCliPath) {
    $VallyCliPath = Join-Path $repoRoot 'evals\_vally\node_modules\@microsoft\vally-cli\dist\index.js'
}
if (-not $GraderPluginPath) {
    $GraderPluginPath = Join-Path $repoRoot 'evals\_vally\dist\graders\finding-match.js'
}
if (-not (Test-Path $VallyCliPath -PathType Leaf)) {
    throw "Vally CLI was not found at '$VallyCliPath'. Run npm ci --prefix evals/_vally."
}
if (-not (Test-Path $GraderPluginPath -PathType Leaf)) {
    throw "The finding-match grader was not found at '$GraderPluginPath'. Run npm run build --prefix evals/_vally."
}

foreach ($trajectoryFile in $trajectoryFiles) {
    $evalDirectory = $trajectoryFile.Directory
    while ($evalDirectory -and -not (Test-Path (Join-Path $evalDirectory.FullName 'eval.yaml'))) {
        $evalDirectory = $evalDirectory.Parent
    }
    if (-not $evalDirectory) {
        throw "Could not find eval.yaml for '$($trajectoryFile.FullName)'"
    }
    $evalSpec = Join-Path $evalDirectory.FullName 'eval.yaml'
    Get-Content -LiteralPath $trajectoryFile.FullName |
        & $NodePath $VallyCliPath grade `
            --eval-spec $evalSpec `
            --run-dir $trajectoryFile.Directory.FullName `
            --grader-plugin $GraderPluginPath `
            --require-pass
    if ($LASTEXITCODE -ne 0) {
        throw "Offline grading failed for '$($trajectoryFile.FullName)'"
    }
}
