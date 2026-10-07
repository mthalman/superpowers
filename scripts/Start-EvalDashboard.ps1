[CmdletBinding(DefaultParameterSetName = 'Latest')]
param(
    [Parameter(ParameterSetName = 'Latest')] [switch] $Latest,
    [Parameter(ParameterSetName = 'RunId', Mandatory)] [long] $RunId,
    [Parameter(ParameterSetName = 'Results', Mandatory)] [string] $ResultsDir,
    [Parameter(ParameterSetName = 'Stop', Mandatory)] [switch] $Stop,
    [ValidateRange(1, 65535)] [int] $Port = 3200,
    [switch] $NoOpen
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (& git rev-parse --show-toplevel).Trim()
$toolDir = Join-Path $repoRoot 'evals\_vally'
$vally = Join-Path $toolDir 'node_modules\@microsoft\vally-cli\dist\index.js'
$cacheRoot = Join-Path $env:LOCALAPPDATA 'superpowers\eval-dashboard'
$statePath = Join-Path $cacheRoot 'server.json'
New-Item -ItemType Directory -Path $cacheRoot -Force | Out-Null

if ($Stop) {
    if (-not (Test-Path $statePath -PathType Leaf)) {
        Write-Host 'No eval dashboard server is recorded.'
        return
    }
    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    $process = Get-Process -Id $state.pid -ErrorAction SilentlyContinue
    if ($process) {
        Stop-Process -Id $state.pid
        $process.WaitForExit(10000)
    }
    Remove-Item -LiteralPath $statePath -Force
    Write-Host "Stopped eval dashboard process $($state.pid)."
    return
}

$node = (Get-Command node -ErrorAction Stop).Source
$nodeVersion = (& $node --version).TrimStart('v')
if ([Version] $nodeVersion -lt [Version] '22.12.0') {
    throw "Vally requires Node.js 22.12.0 or newer; found $nodeVersion."
}

if (-not (Test-Path $vally -PathType Leaf)) {
    & npm ci --prefix $toolDir --no-audit --no-fund
    if ($LASTEXITCODE -ne 0) { throw 'npm ci failed for the Vally toolchain.' }
}

if (Test-Path $statePath -PathType Leaf) {
    & $PSCommandPath -Stop
}

$serveArgs = @(
    $vally,
    'serve'
)
$cacheDir = $null

if ($PSCmdlet.ParameterSetName -eq 'Results') {
    $resolvedResults = (Resolve-Path $ResultsDir).Path
    $cacheDir = Join-Path $cacheRoot 'local'
    New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
    $ingestDir = $resolvedResults
    $store = Join-Path $cacheDir 'eval-history.db'
}
else {
    if ($PSCmdlet.ParameterSetName -eq 'Latest') {
        $json = & gh run list --workflow skill-eval.yml --status success --limit 1 --json databaseId
        if ($LASTEXITCODE -ne 0) { throw 'Failed to query GitHub Actions runs.' }
        $runs = @($json | ConvertFrom-Json)
        if ($runs.Count -eq 0) { throw 'No successful skill-eval workflow run was found.' }
        $RunId = $runs[0].databaseId
    }
    $cacheDir = Join-Path $cacheRoot ([string] $RunId)
    $downloadMarker = Join-Path $cacheDir '.downloaded'
    if (-not (Test-Path $downloadMarker -PathType Leaf)) {
        New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
        & gh run download $RunId --name "eval-history-$RunId" --dir $cacheDir
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to download the eval-history-$RunId artifact."
        }
        [IO.File]::WriteAllText($downloadMarker, '', [Text.UTF8Encoding]::new($false))
    }
    $ingestDir = $cacheDir
    $store = Join-Path $cacheDir 'eval-history.sqlite'
}

$resultFiles = @(Get-ChildItem -LiteralPath $ingestDir -Filter results.jsonl -Recurse -File)
if ($resultFiles.Count -eq 0) {
    throw "No results.jsonl files were found beneath '$ingestDir'."
}
foreach ($resultFile in $resultFiles) {
    & $node $vally ingest $resultFile.DirectoryName --store $store
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to ingest '$($resultFile.DirectoryName)' into '$store'."
    }
}

$serveArgs += @('--store', $store)
$serveArgs += @('--port', [string] $Port)
$serveArgs = @($serveArgs | ForEach-Object {
    if ($_ -match '[\s"]') { '"' + $_.Replace('"', '\"') + '"' } else { $_ }
})
$environment = @{ VALLY_TELEMETRY_OPTOUT = '1' }
$process = Start-Process -FilePath $node -ArgumentList $serveArgs -PassThru -WindowStyle Hidden -Environment $environment

$state = [ordered]@{
    pid = $process.Id
    port = $Port
    cache_dir = $cacheDir
    started_at = [DateTime]::UtcNow.ToString('o')
}
$utf8 = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText($statePath, ($state | ConvertTo-Json), $utf8)

$health = "http://127.0.0.1:$Port/api/health"
$ready = $false
for ($attempt = 0; $attempt -lt 60; $attempt++) {
    if ($process.HasExited) {
        throw "vally serve exited with code $($process.ExitCode) before becoming ready."
    }
    try {
        $response = Invoke-WebRequest -Uri $health -UseBasicParsing -TimeoutSec 2
        if ($response.StatusCode -eq 200) {
            $ready = $true
            break
        }
    }
    catch {
        Start-Sleep -Milliseconds 500
    }
}
if (-not $ready) {
    Stop-Process -Id $process.Id
    throw "vally serve did not become ready at $health."
}

$url = "http://127.0.0.1:$Port/"
if (-not $NoOpen) {
    Start-Process $url
}
Write-Host "Eval dashboard: $url"
