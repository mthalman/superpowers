#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Watch an Azure DevOps pipeline run (or one stage/job within it) until it reaches a
    final outcome, then emit a JSON result on stdout.

.DESCRIPTION
    The script blocks until the monitored target completes. It estimates the expected
    duration from past runs of the same pipeline definition and adapts its polling
    cadence accordingly: slow polling while the target is far from finishing, faster
    polling as it approaches (or passes) the expected finish time. Progress is written
    to stderr; only the final JSON result is written to stdout so the caller can parse
    it reliably.

    Because pipeline runs can take a long time, run this with a long timeout or in the
    background and read the JSON once it returns.

.PARAMETER BuildUrl
    A pipeline run URL, e.g.
    https://dev.azure.com/{org}/{project}/_build/results?buildId=12345
    Organization, project, and buildId are parsed from it. Alternatively pass
    -Organization, -Project, and -BuildId individually.

.PARAMETER Organization
    Org name (e.g. 'dnceng') or full URL (https://dev.azure.com/dnceng). Used with
    -Project and -BuildId instead of -BuildUrl.

.PARAMETER Project
    Project name (e.g. 'internal').

.PARAMETER BuildId
    The numeric run/build id.

.PARAMETER RecordName
    Optional. Name of a specific stage/job/phase to monitor instead of the whole run
    (e.g. 'Windows_Pgo_x64'). When omitted, the whole run is monitored.

.PARAMETER RecordType
    Optional. Disambiguates -RecordName when several timeline records share a name.
    One of: Stage, Phase, Job, Task.

.PARAMETER Pat
    Optional Azure DevOps personal access token. If omitted, the script looks at
    AZURE_DEVOPS_PAT / AZURE_DEVOPS_EXT_PAT / SYSTEM_ACCESSTOKEN, then falls back to an
    `az account get-access-token` Bearer token.

.PARAMETER MinIntervalSeconds
    Floor for the adaptive poll interval. Default 15.

.PARAMETER MaxIntervalSeconds
    Hard ceiling for the adaptive poll interval (also used while waiting for the target
    to start). Default 0 = auto: the ceiling scales with the estimated duration
    (expected/10, clamped to 120s..600s) so long runs aren't polled excessively while
    short runs stay responsive. Pass a positive value to force a fixed ceiling.

.PARAMETER PollSeconds
    Force a fixed poll interval and disable adaptive cadence.

.PARAMETER TimeoutMinutes
    Safety cap on total watch time. Default: max(2 x expected duration, 60), capped at
    600. When reached, the script returns the latest known state with timedOut=true.

.PARAMETER HistorySamples
    How many past completed runs to sample for the duration estimate. Default 10.

.EXAMPLE
    ./Watch-AdoPipeline.ps1 -BuildUrl 'https://dev.azure.com/dnceng/internal/_build/results?buildId=3003258'

.EXAMPLE
    ./Watch-AdoPipeline.ps1 -BuildUrl '...buildId=3003258' -RecordName 'Windows_Pgo_x64' -RecordType Job
#>
[CmdletBinding()]
param(
    [string]$BuildUrl,
    [string]$Organization,
    [string]$Project,
    [int]$BuildId,
    [string]$RecordName,
    [ValidateSet('Stage', 'Phase', 'Job', 'Task')]
    [string]$RecordType,
    [string]$Pat,
    [int]$MinIntervalSeconds = 15,
    [int]$MaxIntervalSeconds = 0,
    [int]$PollSeconds = 0,
    [int]$TimeoutMinutes = 0,
    [int]$HistorySamples = 10,
    [string]$ApiVersion = '7.1'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Azure DevOps resource id used to request an AAD access token via the az CLI.
$AdoResourceId = '499b84ac-1321-427f-aa17-267ca6975798'

function Write-Progress2 {
    param([string]$Message)
    $ts = (Get-Date).ToString('HH:mm:ss')
    [Console]::Error.WriteLine("[$ts] $Message")
}

# Safe property read: build objects omit properties such as 'result' and
# 'finishTime' while a run is still in progress, and Set-StrictMode throws on
# missing-property access. Return $null when the property is absent.
function Get-Prop {
    param($Obj, [string]$Name)
    if ($null -eq $Obj) { return $null }
    $p = $Obj.PSObject.Properties[$Name]
    if ($p) { return $p.Value }
    return $null
}

# Normalise an ADO timestamp to an absolute UTC DateTime. Invoke-RestMethod already
# deserialises JSON dates into [datetime] values (Kind=Utc), so the common path is a
# no-op ToUniversalTime(); the string branch is a safety net that assumes UTC when the
# value carries no offset (ADO always emits UTC). All time math compares the result
# against [datetime]::UtcNow to avoid DateTimeKind mismatches — a Utc-kind value minus a
# Local-kind value silently ignores the offset. Do NOT type this parameter as [string]:
# coercing a DateTime to a string drops its zone and reparses it as local time.
function ConvertTo-UtcTime {
    param($Value)
    if ($null -eq $Value -or '' -eq $Value) { return $null }
    if ($Value -is [datetime]) { return ([datetime]$Value).ToUniversalTime() }
    if ($Value -is [datetimeoffset]) { return $Value.UtcDateTime }
    return ([datetimeoffset]::Parse([string]$Value, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal)).UtcDateTime
}

# ---------------------------------------------------------------------------
# Target resolution
# ---------------------------------------------------------------------------
function Resolve-Target {
    param($BuildUrl, $Organization, $Project, $BuildId)

    if ($BuildUrl) {
        # https://dev.azure.com/{org}/{project}/_build/results?buildId=NNN
        # https://{org}.visualstudio.com/{project}/_build/results?buildId=NNN
        $u = [uri]$BuildUrl
        $org = $null
        $proj = $null
        $segs = $u.AbsolutePath.Trim('/').Split('/')
        if ($u.Host -like '*.visualstudio.com') {
            $org = $u.Host.Split('.')[0]
            if ($segs.Count -ge 1) { $proj = $segs[0] }
        }
        else {
            # dev.azure.com/{org}/{project}/...
            if ($segs.Count -ge 1) { $org = $segs[0] }
            if ($segs.Count -ge 2) { $proj = $segs[1] }
        }
        $q = [System.Web.HttpUtility]::ParseQueryString($u.Query)
        $bid = $q['buildId']
        if (-not $bid) { throw "Could not find buildId in URL: $BuildUrl" }
        return [pscustomobject]@{ Organization = $org; Project = $proj; BuildId = [int]$bid }
    }

    if (-not ($Organization -and $Project -and $BuildId)) {
        throw 'Provide -BuildUrl, or all of -Organization, -Project and -BuildId.'
    }
    $org = $Organization
    if ($org -match '^https?://') {
        $org = ([uri]$org).AbsolutePath.Trim('/').Split('/')[0]
        if (-not $org) { $org = ([uri]$Organization).Host.Split('.')[0] }
    }
    return [pscustomobject]@{ Organization = $org; Project = $Project; BuildId = $BuildId }
}

# ---------------------------------------------------------------------------
# Authentication (PAT or az Bearer token with refresh)
# ---------------------------------------------------------------------------
$script:AuthMode = $null      # 'pat' or 'az'
$script:AuthHeaderValue = $null
$script:TokenExpiresOn = [datetime]::MaxValue

function Initialize-Auth {
    param($Pat)
    $patValue = $Pat
    foreach ($n in 'AZURE_DEVOPS_PAT', 'AZURE_DEVOPS_EXT_PAT', 'SYSTEM_ACCESSTOKEN') {
        if (-not $patValue) { $patValue = [Environment]::GetEnvironmentVariable($n) }
    }
    if ($patValue) {
        $bytes = [Text.Encoding]::ASCII.GetBytes(":$patValue")
        $script:AuthHeaderValue = 'Basic ' + [Convert]::ToBase64String($bytes)
        $script:AuthMode = 'pat'
        Write-Progress2 'Auth: using personal access token.'
        return
    }
    # Fall back to az access token.
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw 'No PAT found and the az CLI is not available. Set AZURE_DEVOPS_PAT or install/login to az.'
    }
    $script:AuthMode = 'az'
    Update-AzToken
    Write-Progress2 'Auth: using az access token (auto-refreshed).'
}

function Update-AzToken {
    $json = az account get-access-token --resource $AdoResourceId -o json 2>$null
    if (-not $json) { throw "Failed to get an az access token. Run 'az login'." }
    $tok = $json | ConvertFrom-Json
    $script:AuthHeaderValue = "Bearer $($tok.accessToken)"
    try { $script:TokenExpiresOn = [datetime]$tok.expiresOn } catch { $script:TokenExpiresOn = (Get-Date).AddMinutes(50) }
}

function Get-AuthHeader {
    if ($script:AuthMode -eq 'az' -and (Get-Date) -gt $script:TokenExpiresOn.AddMinutes(-5)) {
        Update-AzToken
    }
    return @{ Authorization = $script:AuthHeaderValue }
}

# ---------------------------------------------------------------------------
# REST helper with transient-failure retry and 401 token refresh
# ---------------------------------------------------------------------------
function Invoke-Ado {
    param([string]$Uri, [int]$MaxRetries = 4)
    $attempt = 0
    while ($true) {
        $attempt++
        try {
            return Invoke-RestMethod -Uri $Uri -Headers (Get-AuthHeader) -Method Get
        }
        catch {
            $status = $null
            try { $status = [int]$_.Exception.Response.StatusCode } catch { }
            if ($status -eq 401 -and $script:AuthMode -eq 'az' -and $attempt -le 2) {
                Write-Progress2 'Got 401; refreshing token and retrying.'
                Update-AzToken
                continue
            }
            if ($attempt -gt $MaxRetries) { throw }
            $backoff = [math]::Min(30, 2 * $attempt)
            Write-Progress2 "Request failed (attempt $attempt): $($_.Exception.Message). Retrying in ${backoff}s."
            Start-Sleep -Seconds $backoff
        }
    }
}

function Get-Median {
    param([double[]]$Values)
    $sorted = @($Values | Sort-Object)
    $n = $sorted.Count
    if ($n -eq 0) { return $null }
    if ($n % 2 -eq 1) { return $sorted[[int](($n - 1) / 2)] }
    return ($sorted[$n / 2 - 1] + $sorted[$n / 2]) / 2.0
}

# ---------------------------------------------------------------------------
# Duration estimation
# ---------------------------------------------------------------------------
function Get-BuildDurationEstimate {
    param($BaseUri, [int]$DefinitionId, [int]$Samples)
    $uri = "$BaseUri/build/builds?definitions=$DefinitionId&statusFilter=completed&`$top=$Samples&queryOrder=finishTimeDescending&api-version=$ApiVersion"
    $resp = Invoke-Ado -Uri $uri
    $durations = @()
    foreach ($b in $resp.value) {
        if ($b.startTime -and $b.finishTime) {
            $d = ([datetime]$b.finishTime - [datetime]$b.startTime).TotalMinutes
            if ($d -gt 0) { $durations += $d }
        }
    }
    if ($durations.Count -eq 0) { return $null }
    return [pscustomobject]@{
        Median  = [math]::Round((Get-Median $durations), 1)
        Samples = $durations.Count
    }
}

function Get-RecordDurationEstimate {
    param($BaseUri, [int]$DefinitionId, [string]$RecordName, [string]$RecordType, [int]$Samples)
    $uri = "$BaseUri/build/builds?definitions=$DefinitionId&statusFilter=completed&`$top=$Samples&queryOrder=finishTimeDescending&api-version=$ApiVersion"
    $resp = Invoke-Ado -Uri $uri
    $durations = @()
    foreach ($b in $resp.value) {
        try {
            $tl = Invoke-Ado -Uri "$BaseUri/build/builds/$($b.id)/timeline?api-version=$ApiVersion"
        }
        catch { continue }
        if (-not $tl.records) { continue }
        $match = $tl.records | Where-Object {
            $_.name -eq $RecordName -and (-not $RecordType -or $_.type -eq $RecordType) -and
            $_.startTime -and $_.finishTime
        } | Select-Object -First 1
        if ($match) {
            $d = ([datetime]$match.finishTime - [datetime]$match.startTime).TotalMinutes
            if ($d -gt 0) { $durations += $d }
        }
    }
    if ($durations.Count -eq 0) { return $null }
    return [pscustomobject]@{
        Median  = [math]::Round((Get-Median $durations), 1)
        Samples = $durations.Count
    }
}

# ---------------------------------------------------------------------------
# Timeline record selection
# ---------------------------------------------------------------------------
function Select-Record {
    param($Records, [string]$RecordName, [string]$RecordType)
    $candidates = @($Records | Where-Object {
            $_.name -eq $RecordName -and (-not $RecordType -or $_.type -eq $RecordType)
        })
    if ($candidates.Count -eq 0) { return $null }
    if ($candidates.Count -eq 1) { return $candidates[0] }
    # Prefer a record that is not yet finished, else the most recently started.
    $active = @($candidates | Where-Object { $_.state -ne 'completed' })
    if ($active.Count -ge 1) { return $active[0] }
    return ($candidates | Sort-Object { if ($_.startTime) { [datetime]$_.startTime } else { [datetime]::MinValue } } -Descending | Select-Object -First 1)
}

# ---------------------------------------------------------------------------
# Cadence
# ---------------------------------------------------------------------------
function Get-Interval {
    param($ExpectedFinish, $Now)
    if ($PollSeconds -gt 0) { return $PollSeconds }
    if (-not $ExpectedFinish) { return $effectiveMaxInterval }
    $remaining = ($ExpectedFinish - $Now).TotalSeconds
    $interval = [int][math]::Round($remaining / 5.0)
    if ($interval -lt $MinIntervalSeconds) { $interval = $MinIntervalSeconds }
    if ($interval -gt $effectiveMaxInterval) { $interval = $effectiveMaxInterval }
    return $interval
}

# ===========================================================================
# Main
# ===========================================================================
Add-Type -AssemblyName System.Web | Out-Null

$target = Resolve-Target -BuildUrl $BuildUrl -Organization $Organization -Project $Project -BuildId $BuildId
$org = $target.Organization
$proj = $target.Project
$bid = $target.BuildId
$baseUri = "https://dev.azure.com/$org/$proj/_apis"
$webUrl = "https://dev.azure.com/$org/$proj/_build/results?buildId=$bid"

Initialize-Auth -Pat $Pat

$modeLabel = if ($RecordName) { "record '$RecordName'" } else { 'whole run' }
Write-Progress2 "Monitoring $modeLabel of build $bid in $org/$proj."

# Initial build fetch to get definition id and confirm access.
$build = Invoke-Ado -Uri "$baseUri/build/builds/$bid`?api-version=$ApiVersion"
$defId = [int]$build.definition.id
$defName = $build.definition.name
Write-Progress2 "Definition: $defName (id $defId). Current status: $($build.status)."

# Duration estimate -> expected finish.
$estimate = $null
if ($RecordName) {
    Write-Progress2 "Estimating duration of record '$RecordName' from up to $HistorySamples past runs..."
    $estimate = Get-RecordDurationEstimate -BaseUri $baseUri -DefinitionId $defId -RecordName $RecordName -RecordType $RecordType -Samples $HistorySamples
}
else {
    Write-Progress2 "Estimating run duration from up to $HistorySamples past runs..."
    $estimate = Get-BuildDurationEstimate -BaseUri $baseUri -DefinitionId $defId -Samples $HistorySamples
}
if ($estimate) {
    Write-Progress2 "Estimated duration: $($estimate.Median) min (from $($estimate.Samples) past samples)."
}
else {
    Write-Progress2 'No past-run data available; using ceiling interval until target is near completion.'
}

# Effective poll-interval ceiling. By default it scales with the estimated duration so
# long runs aren't polled excessively (a 3 h run tolerates a ~18 min ceiling) while
# short runs stay responsive. An explicit positive -MaxIntervalSeconds overrides this.
if ($MaxIntervalSeconds -gt 0) {
    $effectiveMaxInterval = $MaxIntervalSeconds
}
elseif ($estimate) {
    $scaled = [int][math]::Round($estimate.Median * 60 / 10.0)
    $effectiveMaxInterval = [math]::Max(120, [math]::Min(600, $scaled))
}
else {
    $effectiveMaxInterval = 120
}
if ($effectiveMaxInterval -lt $MinIntervalSeconds) { $effectiveMaxInterval = $MinIntervalSeconds }
Write-Progress2 "Poll interval range: ${MinIntervalSeconds}s..${effectiveMaxInterval}s."

# Timeout default.
if ($TimeoutMinutes -le 0) {
    $base = if ($estimate) { $estimate.Median } else { 30 }
    $TimeoutMinutes = [int][math]::Min(600, [math]::Max(60, $base * 2))
}
Write-Progress2 "Safety timeout: $TimeoutMinutes min."

$watchStart = Get-Date
$deadline = $watchStart.AddMinutes($TimeoutMinutes)
$polls = 0
$finalState = $null      # the object (build or record) at completion
$finalTimeline = $null
$timedOut = $false

while ($true) {
    $polls++

    if ($RecordName) {
        $timeline = Invoke-Ado -Uri "$baseUri/build/builds/$bid/timeline?api-version=$ApiVersion"
        $record = if ($timeline.records) { Select-Record -Records $timeline.records -RecordName $RecordName -RecordType $RecordType } else { $null }

        if (-not $record) {
            Write-Progress2 "Poll #${polls}: record '$RecordName' not present yet."
            $expectedFinish = $null
        }
        elseif ((Get-Prop $record 'state') -eq 'completed') {
            $finalState = $record
            $finalTimeline = $timeline
            break
        }
        else {
            $recStart = Get-Prop $record 'startTime'
            $recState = Get-Prop $record 'state'
            if ($recStart) {
                $expectedFinish = if ($estimate) { (ConvertTo-UtcTime $recStart).AddMinutes($estimate.Median) } else { $null }
                $startedAt = (ConvertTo-UtcTime $recStart).ToString('HH:mm:ss') + 'Z'
                Write-Progress2 "Poll #${polls}: record '$RecordName' state=$recState (started $startedAt)."
            }
            else {
                $expectedFinish = $null
                Write-Progress2 "Poll #${polls}: record '$RecordName' state=$recState."
            }
        }
    }
    else {
        $build = Invoke-Ado -Uri "$baseUri/build/builds/$bid`?api-version=$ApiVersion"
        if ($build.status -eq 'completed') {
            $finalState = $build
            break
        }
        $bStart = Get-Prop $build 'startTime'
        if ($bStart) {
            $expectedFinish = if ($estimate) { (ConvertTo-UtcTime $bStart).AddMinutes($estimate.Median) } else { $null }
        }
        else {
            $expectedFinish = $null
        }
        Write-Progress2 "Poll #${polls}: build status=$($build.status)."
    }

    if ((Get-Date) -ge $deadline) {
        Write-Progress2 "Timeout of $TimeoutMinutes min reached before completion."
        $timedOut = $true
        break
    }

    $interval = Get-Interval -ExpectedFinish $expectedFinish -Now ([datetime]::UtcNow)
    # Don't sleep past the deadline.
    $secsLeft = [int]($deadline - (Get-Date)).TotalSeconds
    if ($secsLeft -le 0) { $timedOut = $true; break }
    if ($interval -gt $secsLeft) { $interval = $secsLeft }
    Write-Progress2 "Sleeping ${interval}s before next poll."
    Start-Sleep -Seconds $interval
}

# ---------------------------------------------------------------------------
# Build the result object
# ---------------------------------------------------------------------------
function Get-Duration {
    param($Start, $Finish)
    if ($Start -and $Finish) {
        return [math]::Round(((ConvertTo-UtcTime $Finish) - (ConvertTo-UtcTime $Start)).TotalMinutes, 1)
    }
    return $null
}

$failures = @()
$issues = @()

if ($RecordName) {
    if ($timedOut -and -not $finalState) {
        try {
            $tl = Invoke-Ado -Uri "$baseUri/build/builds/$bid/timeline?api-version=$ApiVersion"
            $finalState = if ($tl.records) { Select-Record -Records $tl.records -RecordName $RecordName -RecordType $RecordType } else { $null }
            $finalTimeline = $tl
        }
        catch { }
    }
    $name = $RecordName
    $status = if ($finalState) { Get-Prop $finalState 'state' } else { 'unknown' }
    $resultVal = if ($finalState) { Get-Prop $finalState 'result' } else { $null }
    $startT = if ($finalState) { Get-Prop $finalState 'startTime' } else { $null }
    $finishT = if ($finalState) { Get-Prop $finalState 'finishTime' } else { $null }
    # Non-clean descendant leaf records under the monitored record. Real failures
    # (failed/canceled) and softer "had problems" outcomes (partiallySucceeded/
    # succeededWithIssues) are tracked separately so a partial run can still point at
    # the offending job without mislabelling it as a failure.
    if ($finalState -and $finalTimeline -and $finalTimeline.records) {
        $byParent = @{}
        foreach ($r in $finalTimeline.records) {
            $parent = Get-Prop $r 'parentId'
            if (-not $parent) { $parent = '<root>' }
            if (-not $byParent.ContainsKey($parent)) { $byParent[$parent] = @() }
            $byParent[$parent] += $r
        }
        $stack = New-Object System.Collections.Stack
        $stack.Push($finalState.id)
        while ($stack.Count -gt 0) {
            $cur = $stack.Pop()
            if ($byParent.ContainsKey($cur)) {
                foreach ($child in $byParent[$cur]) {
                    $childResult = Get-Prop $child 'result'
                    if ($childResult -in 'failed', 'canceled') {
                        $failures += [pscustomobject]@{ name = $child.name; type = $child.type; result = $childResult }
                    }
                    elseif ($childResult -in 'partiallySucceeded', 'succeededWithIssues') {
                        $issues += [pscustomobject]@{ name = $child.name; type = $child.type; result = $childResult }
                    }
                    $stack.Push($child.id)
                }
            }
        }
    }
}
else {
    $name = $defName
    $status = $build.status
    $resultVal = Get-Prop $build 'result'
    $startT = Get-Prop $build 'startTime'
    $finishT = Get-Prop $build 'finishTime'
    if ($status -eq 'completed') {
        try {
            $tl = Invoke-Ado -Uri "$baseUri/build/builds/$bid/timeline?api-version=$ApiVersion"
            foreach ($r in @($tl.records | Where-Object { $_.type -in 'Job', 'Task' })) {
                $rr = Get-Prop $r 'result'
                if ($rr -in 'failed', 'canceled') {
                    $failures += [pscustomobject]@{ name = $r.name; type = $r.type; result = $rr }
                }
                elseif ($rr -in 'partiallySucceeded', 'succeededWithIssues') {
                    $issues += [pscustomobject]@{ name = $r.name; type = $r.type; result = $rr }
                }
            }
        }
        catch { }
    }
}

$result = [ordered]@{
    kind                    = if ($RecordName) { 'record' } else { 'build' }
    organization            = $org
    project                 = $proj
    buildId                 = $bid
    definition              = [ordered]@{ id = $defId; name = $defName }
    name                    = $name
    recordType              = $RecordType
    status                  = $status
    result                  = $resultVal
    startTime               = $startT
    finishTime              = $finishT
    durationMinutes         = (Get-Duration $startT $finishT)
    expectedDurationMinutes = if ($estimate) { $estimate.Median } else { $null }
    estimateSamples         = if ($estimate) { $estimate.Samples } else { 0 }
    url                     = $webUrl
    polls                   = $polls
    monitorMinutes          = [math]::Round(((Get-Date) - $watchStart).TotalMinutes, 1)
    timedOut                = $timedOut
    failures                = @($failures | Select-Object -First 25)
    failureCount            = $failures.Count
    issues                  = @($issues | Select-Object -First 25)
    issueCount              = $issues.Count
}

$outcome = if ($timedOut) { 'TIMED OUT' } else { "$status / $resultVal" }
Write-Progress2 "Done. Outcome: $outcome. Failures: $($failures.Count). Issues: $($issues.Count). Polls: $polls."

$result | ConvertTo-Json -Depth 6
