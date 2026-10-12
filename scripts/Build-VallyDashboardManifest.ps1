[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $PagesDir,
    [string] $Repository,
    [int] $SparklineLength = 20,
    [int] $RegressionWindow = 10
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$dataDir = Join-Path $PagesDir 'data'
New-Item -ItemType Directory -Path $dataDir -Force | Out-Null

if (-not $Repository) {
    $Repository = $env:GITHUB_REPOSITORY
}
if (-not $Repository) {
    $remote = (& git remote get-url origin 2>$null)
    if ($remote -match 'github\.com[:/](.+?)(?:\.git)?$') {
        $Repository = $Matches[1]
    }
}

function Get-PassRate($row) {
    if ($row.status -ne 'ok' -or $null -eq $row.metrics) { return $null }
    $property = $row.metrics.PSObject.Properties['pass_rate']
    if ($null -eq $property) { return $null }
    $value = $property.Value
    if ($null -eq $value) { return $null }
    return [double] $value
}

function Get-RunKind($row) {
    $property = $row.PSObject.Properties['run_kind']
    if ($null -eq $property) { return 'legacy' }
    return [string] $property.Value
}

function Get-BiggestDrop([object[]] $Rows) {
    $okRows = @($Rows | Where-Object {
        (Get-RunKind $_) -eq 'nightly' -and $null -ne (Get-PassRate $_)
    })
    if ($okRows.Count -lt 2) { return $null }
    $transitions = for ($i = 1; $i -lt $okRows.Count; $i++) {
        $from = Get-PassRate $okRows[$i - 1]
        $to = Get-PassRate $okRows[$i]
        [pscustomobject]@{
            from = $from
            to = $to
            delta = [Math]::Round($to - $from, 4)
            commit = $okRows[$i].commit
            short_sha = $okRows[$i].short_sha
            timestamp = $okRows[$i].timestamp
        }
    }
    $recent = @($transitions | Select-Object -Last $RegressionWindow)
    return $recent |
        Where-Object { $_.delta -lt 0 } |
        Sort-Object delta |
        Select-Object -First 1
}

$skills = @()
foreach ($directory in @(Get-ChildItem -LiteralPath $dataDir -Directory -ErrorAction SilentlyContinue)) {
    if ($directory.Name -in @('uplift', 'nightly-runs')) { continue }
    $historyPath = Join-Path $directory.FullName 'history.jsonl'
    if (-not (Test-Path $historyPath -PathType Leaf)) { continue }
    $rows = @(
        Get-Content -LiteralPath $historyPath |
            Where-Object { $_.Trim() } |
            ForEach-Object { $_ | ConvertFrom-Json }
    )
    if ($rows.Count -eq 0) { continue }

    $nightlyRows = @($rows | Where-Object { (Get-RunKind $_) -eq 'nightly' })
    $latest = if ($nightlyRows.Count -gt 0) { $nightlyRows[-1] } else { $rows[-1] }
    $previousOk = @($nightlyRows | Where-Object { $null -ne (Get-PassRate $_) } | Select-Object -Last 2)
    $delta = $null
    if ($previousOk.Count -eq 2 -and $null -ne (Get-PassRate $latest)) {
        $delta = [Math]::Round(
            (Get-PassRate $previousOk[1]) - (Get-PassRate $previousOk[0]),
            4
        )
    }
    $latest | Add-Member -NotePropertyName delta_from_previous -NotePropertyValue $delta -Force

    $sparkline = @($rows | Select-Object -Last $SparklineLength | ForEach-Object {
        [pscustomobject]@{
            timestamp = $_.timestamp
            short_sha = $_.short_sha
            status = $_.status
            pass_rate = Get-PassRate $_
            run_kind = Get-RunKind $_
        }
    })

    $skills += [pscustomobject]@{
        name = $directory.Name
        run_count = $rows.Count
        latest = $latest
        sparkline = $sparkline
        biggest_drop_last_10 = Get-BiggestDrop $rows
    }
}

$worst = $skills |
    Where-Object { $null -ne $_.biggest_drop_last_10 } |
    ForEach-Object {
        [pscustomobject]@{
            skill = $_.name
            from = $_.biggest_drop_last_10.from
            to = $_.biggest_drop_last_10.to
            delta = $_.biggest_drop_last_10.delta
            commit = $_.biggest_drop_last_10.commit
            short_sha = $_.biggest_drop_last_10.short_sha
            timestamp = $_.biggest_drop_last_10.timestamp
        }
    } |
    Sort-Object delta |
    Select-Object -First 1

$manifest = [ordered]@{
    schema_version = 2
    generated_at = [DateTime]::UtcNow.ToString('o')
    repository = $Repository
    sparkline_length = $SparklineLength
    skills = @($skills | Sort-Object name)
    worst_recent_drop = $worst
    nightly_index = if (Test-Path (Join-Path $dataDir 'nightly-runs\index.json')) {
        'data/nightly-runs/index.json'
    } else {
        $null
    }
    uplift_history = if (Test-Path (Join-Path $dataDir 'uplift\history.jsonl')) {
        'data/uplift/history.jsonl'
    } else {
        $null
    }
}

$utf8 = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText(
    (Join-Path $dataDir 'manifest.json'),
    ($manifest | ConvertTo-Json -Depth 20),
    $utf8
)
