[CmdletBinding()]
param(
    [string] $RepoPath = (Get-Location).Path,
    [string] $RemoteName,
    [string] $BaseBranch,
    [switch] $SkipPullRequests,
    [string] $PullRequestDataPath,
    [string] $ActivityDataPath,
    [ValidateRange(0, 3650)]
    [int] $RecentActivityDays = 4,
    [switch] $IncludeSize,
    [switch] $AsJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Git {
    param(
        [Parameter(Mandatory)][string] $WorkingDirectory,
        [Parameter(Mandatory)][string[]] $Arguments,
        [switch] $AllowFailure
    )

    $output = @(& git --no-optional-locks -C $WorkingDirectory @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0 -and -not $AllowFailure) {
        $detail = ($output | ForEach-Object { "$_" }) -join [Environment]::NewLine
        throw "git $($Arguments -join ' ') failed in '$WorkingDirectory' with exit code $exitCode.`n$detail"
    }

    [pscustomobject]@{
        ExitCode = $exitCode
        Output   = @($output | ForEach-Object { "$_" })
    }
}

function Test-GitRef {
    param(
        [Parameter(Mandatory)][string] $WorkingDirectory,
        [Parameter(Mandatory)][string] $Ref
    )

    (Invoke-Git -WorkingDirectory $WorkingDirectory -Arguments @(
        'show-ref', '--verify', '--quiet', $Ref
    ) -AllowFailure).ExitCode -eq 0
}

function Get-WorktreeRecords {
    param([Parameter(Mandatory)][string] $WorkingDirectory)

    $lines = (Invoke-Git -WorkingDirectory $WorkingDirectory -Arguments @(
        'worktree', 'list', '--porcelain'
    )).Output
    $records = [System.Collections.Generic.List[object]]::new()
    $current = $null

    foreach ($line in $lines) {
        if ($line.StartsWith('worktree ')) {
            if ($null -ne $current) {
                $records.Add([pscustomobject]$current)
            }
            $current = [ordered]@{
                Path     = $line.Substring('worktree '.Length)
                Head     = $null
                Branch   = $null
                Detached = $false
                Locked   = $false
                Prunable = $false
                Reason   = $null
            }
            continue
        }

        if ($null -eq $current) {
            continue
        }

        if ($line.StartsWith('HEAD ')) {
            $current.Head = $line.Substring('HEAD '.Length)
        }
        elseif ($line.StartsWith('branch refs/heads/')) {
            $current.Branch = $line.Substring('branch refs/heads/'.Length)
        }
        elseif ($line -eq 'detached') {
            $current.Detached = $true
        }
        elseif ($line.StartsWith('locked')) {
            $current.Locked = $true
            if ($line.Length -gt 'locked'.Length) {
                $current.Reason = $line.Substring('locked'.Length).Trim()
            }
        }
        elseif ($line.StartsWith('prunable')) {
            $current.Prunable = $true
            if ($line.Length -gt 'prunable'.Length) {
                $current.Reason = $line.Substring('prunable'.Length).Trim()
            }
        }
    }

    if ($null -ne $current) {
        $records.Add([pscustomobject]$current)
    }

    return $records.ToArray()
}

function Resolve-GitHubRepository {
    param([string] $RemoteUrl)

    if (-not $RemoteUrl) {
        return $null
    }

    $patterns = @(
        '^https://(?:[^@/]+@)?github\.com/(?<owner>[^/]+)/(?<repo>[^/]+?)(?:\.git)?$',
        '^ssh://git@github\.com/(?<owner>[^/]+)/(?<repo>[^/]+?)(?:\.git)?$',
        '^git@github\.com:(?<owner>[^/]+)/(?<repo>[^/]+?)(?:\.git)?$'
    )

    foreach ($pattern in $patterns) {
        if ($RemoteUrl -match $pattern) {
            return "$($Matches.owner)/$($Matches.repo)"
        }
    }

    return $null
}

function Get-PullRequestData {
    param(
        [string] $Repository,
        [string] $DataPath,
        [switch] $Skip
    )

    if ($DataPath) {
        $resolved = (Resolve-Path -LiteralPath $DataPath).Path
        return [pscustomobject]@{
            Status = 'available'
            Items  = [object[]]@(Get-Content -LiteralPath $resolved -Raw | ConvertFrom-Json)
        }
    }

    if ($Skip) {
        return [pscustomobject]@{
            Status = 'skipped'
            Items  = [object[]]@()
        }
    }

    if (-not $Repository) {
        return [pscustomobject]@{
            Status = 'not-applicable'
            Items  = [object[]]@()
        }
    }

    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-Warning "GitHub CLI is unavailable for '$Repository'. PR state is unknown."
        return [pscustomobject]@{
            Status = 'unavailable'
            Items  = [object[]]@()
        }
    }

    $json = @(& gh pr list `
        --repo $Repository `
        --state all `
        --limit 1000 `
        --json number,state,headRefName,headRefOid,mergedAt,url 2>&1)
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Could not query pull requests for '$Repository'. PR state is unknown."
        return [pscustomobject]@{
            Status = 'unavailable'
            Items  = [object[]]@()
        }
    }

    return [pscustomobject]@{
        Status = 'available'
        Items  = [object[]]@(($json -join [Environment]::NewLine) | ConvertFrom-Json)
    }
}

function Get-ActivityMap {
    param([string] $DataPath)

    $map = [System.Collections.Generic.Dictionary[string, datetimeoffset]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    if (-not $DataPath) {
        return $map
    }

    $resolved = (Resolve-Path -LiteralPath $DataPath).Path
    $data = Get-Content -LiteralPath $resolved -Raw | ConvertFrom-Json
    foreach ($property in $data.PSObject.Properties) {
        $map[$property.Name] = [datetimeoffset]$property.Value
    }
    return $map
}

function Get-DirectorySize {
    param([Parameter(Mandatory)][string] $Path)

    $traversalErrors = @()
    $files = @(
        Get-ChildItem `
            -LiteralPath $Path `
            -File `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue `
            -ErrorVariable traversalErrors
    )
    $sizeBytes = [int64]0
    if ($files.Count -gt 0) {
        $sizeBytes = [int64](($files | Measure-Object -Property Length -Sum).Sum)
    }

    [pscustomobject]@{
        SizeBytes    = $sizeBytes
        SizeComplete = $traversalErrors.Count -eq 0
        ErrorCount   = $traversalErrors.Count
    }
}

$repoResult = Invoke-Git -WorkingDirectory $RepoPath -Arguments @(
    'rev-parse', '--show-toplevel'
)
$repoRoot = [System.IO.Path]::GetFullPath($repoResult.Output[0])
$worktrees = @(Get-WorktreeRecords -WorkingDirectory $repoRoot)
if ($worktrees.Count -eq 0) {
    throw "No worktrees were reported for '$repoRoot'."
}

$mainWorktree = $worktrees[0]
$mainBranch = $mainWorktree.Branch

if (-not $RemoteName -and $mainBranch) {
    $remoteResult = Invoke-Git -WorkingDirectory $repoRoot -Arguments @(
        'config', '--get', "branch.$mainBranch.remote"
    ) -AllowFailure
    if ($remoteResult.ExitCode -eq 0 -and $remoteResult.Output.Count -gt 0 -and $remoteResult.Output[0] -ne '.') {
        $RemoteName = $remoteResult.Output[0]
    }
}

if (-not $RemoteName) {
    $remotes = (Invoke-Git -WorkingDirectory $repoRoot -Arguments @('remote')).Output
    if ($remotes.Count -eq 1) {
        $RemoteName = $remotes[0]
    }
    elseif ($remotes.Count -gt 1) {
        Write-Warning 'Multiple remotes exist and no upstream remote could be selected. Pass -RemoteName for remote and PR analysis.'
    }
}

$remoteUrl = $null
if ($RemoteName) {
    $remoteUrlResult = Invoke-Git -WorkingDirectory $repoRoot -Arguments @(
        'remote', 'get-url', $RemoteName
    ) -AllowFailure
    if ($remoteUrlResult.ExitCode -ne 0) {
        throw "Remote '$RemoteName' does not exist in '$repoRoot'."
    }
    $remoteUrl = $remoteUrlResult.Output[0]
}

if (-not $BaseBranch -and $RemoteName) {
    $remoteHead = Invoke-Git -WorkingDirectory $repoRoot -Arguments @(
        'symbolic-ref', '--quiet', '--short', "refs/remotes/$RemoteName/HEAD"
    ) -AllowFailure
    if ($remoteHead.ExitCode -eq 0 -and $remoteHead.Output.Count -gt 0) {
        $prefix = "$RemoteName/"
        if ($remoteHead.Output[0].StartsWith($prefix)) {
            $BaseBranch = $remoteHead.Output[0].Substring($prefix.Length)
        }
    }
}

if (-not $BaseBranch) {
    $localBaseCandidates = [System.Collections.Generic.List[string]]::new()
    foreach ($candidate in 'main', 'master') {
        if (Test-GitRef -WorkingDirectory $repoRoot -Ref "refs/heads/$candidate") {
            $localBaseCandidates.Add($candidate)
        }
    }

    if ($localBaseCandidates.Count -eq 1 -and $mainBranch -eq $localBaseCandidates[0]) {
        $BaseBranch = $localBaseCandidates[0]
    }
}

if (-not $BaseBranch) {
    throw 'Could not determine a base branch. Pass -BaseBranch explicitly.'
}

$baseRef = $null
if ($RemoteName -and (Test-GitRef -WorkingDirectory $repoRoot -Ref "refs/remotes/$RemoteName/$BaseBranch")) {
    $baseRef = "refs/remotes/$RemoteName/$BaseBranch"
}
elseif (Test-GitRef -WorkingDirectory $repoRoot -Ref "refs/heads/$BaseBranch") {
    $baseRef = "refs/heads/$BaseBranch"
}

if (-not $baseRef) {
    throw "Could not resolve base branch '$BaseBranch' locally."
}

$baseTimestamp = (Invoke-Git -WorkingDirectory $repoRoot -Arguments @(
    'log', '-1', '--format=%ct', $baseRef
)).Output[0]
$now = [datetimeoffset]::UtcNow
$baseAgeDays = [math]::Floor(($now - [datetimeoffset]::FromUnixTimeSeconds([int64]$baseTimestamp)).TotalDays)

$githubRepository = Resolve-GitHubRepository -RemoteUrl $remoteUrl
$pullRequestLookup = Get-PullRequestData `
    -Repository $githubRepository `
    -DataPath $PullRequestDataPath `
    -Skip:$SkipPullRequests
$pullRequests = @($pullRequestLookup.Items)
$activity = Get-ActivityMap -DataPath $ActivityDataPath
$results = [System.Collections.Generic.List[object]]::new()

foreach ($worktree in $worktrees | Select-Object -Skip 1) {
    $path = [System.IO.Path]::GetFullPath($worktree.Path)
    if ($worktree.Prunable -or -not [System.IO.Directory]::Exists($path)) {
        $results.Add([pscustomobject]@{
            Worktree          = $path
            Branch            = $worktree.Branch
            Head              = $worktree.Head
            AgeDays           = $null
            SizeBytes         = $null
            SizeComplete      = $null
            Dirty             = 'unknown'
            AssumeUnchanged   = $null
            SkipWorktree      = $null
            RemoteState       = 'unknown'
            BaseRef           = $baseRef
            BaseRefAgeDays    = $baseAgeDays
            MergeState        = 'unknown'
            PullRequestNumber = $null
            PullRequestState  = 'unknown'
            PullRequestLookup = $pullRequestLookup.Status
            PullRequestUrl    = $null
            PullRequestAtHead = $false
            LastActivityUtc   = $null
            Locked            = $worktree.Locked
            Prunable          = $true
            Note              = $worktree.Reason
            Bucket            = 'review-prunable'
        })
        continue
    }

    $statusLines = (Invoke-Git -WorkingDirectory $path -Arguments @(
        'status', '--porcelain=v1', '--untracked-files=all',
        '--ignore-submodules=none'
    )).Output
    $trackedCount = @($statusLines | Where-Object { $_ -notmatch '^\?\?' }).Count
    $untrackedCount = @($statusLines | Where-Object { $_ -match '^\?\?' }).Count
    $indexFlags = (Invoke-Git -WorkingDirectory $path -Arguments @(
        'ls-files', '-v'
    )).Output
    $assumeUnchangedCount = @($indexFlags | Where-Object { $_ -cmatch '^[a-z] ' }).Count
    $skipWorktreeCount = @($indexFlags | Where-Object { $_ -cmatch '^S ' }).Count
    $hiddenIndexFlagCount = $assumeUnchangedCount + $skipWorktreeCount
    $dirtyState = if ($trackedCount -gt 0) {
        "wip:$trackedCount"
    }
    elseif ($hiddenIndexFlagCount -gt 0) {
        "index-flags:$hiddenIndexFlagCount"
    }
    elseif ($untrackedCount -gt 0) {
        "scratch:$untrackedCount"
    }
    else {
        'clean'
    }

    $headTimestamp = (Invoke-Git -WorkingDirectory $path -Arguments @(
        'log', '-1', '--format=%ct', 'HEAD'
    )).Output[0]
    $ageDays = [math]::Floor(($now - [datetimeoffset]::FromUnixTimeSeconds([int64]$headTimestamp)).TotalDays)

    $mergedLocally = (Invoke-Git -WorkingDirectory $repoRoot -Arguments @(
        'merge-base', '--is-ancestor', $worktree.Head, $baseRef
    ) -AllowFailure).ExitCode -eq 0

    $remoteState = if ($worktree.Detached -or -not $worktree.Branch) {
        'detached'
    }
    elseif (-not $RemoteName) {
        'remote-unknown'
    }
    elseif (-not (Test-GitRef -WorkingDirectory $repoRoot -Ref "refs/remotes/$RemoteName/$($worktree.Branch)")) {
        'unpushed'
    }
    else {
        $counts = (Invoke-Git -WorkingDirectory $repoRoot -Arguments @(
            'rev-list', '--left-right', '--count',
            "refs/remotes/$RemoteName/$($worktree.Branch)...$($worktree.Head)"
        )).Output[0] -split '\s+'
        $behind = [int]$counts[0]
        $ahead = [int]$counts[1]
        if ($ahead -gt 0 -and $behind -gt 0) {
            "diverged:+$ahead/-$behind"
        }
        elseif ($ahead -gt 0) {
            "ahead:$ahead"
        }
        elseif ($behind -gt 0) {
            "behind:$behind"
        }
        else {
            'synchronized'
        }
    }

    $branchPullRequests = @($pullRequests | Where-Object {
        $_.headRefName -eq $worktree.Branch
    })
    $pullRequest = @(
        $branchPullRequests | Sort-Object @{
            Expression = {
                if ($_.state -eq 'OPEN') { 0 }
                elseif ($_.state -eq 'MERGED') { 1 }
                else { 2 }
            }
        }, @{ Expression = { [int]$_.number }; Descending = $true } |
            Select-Object -First 1
    )

    $prNumber = $null
    $prState = if ($pullRequestLookup.Status -eq 'unavailable') {
        'unknown'
    }
    elseif ($pullRequestLookup.Status -eq 'skipped') {
        'skipped'
    }
    else {
        'none'
    }
    $prUrl = $null
    $prCoversHead = $false
    if ($pullRequest.Count -gt 0) {
        $selectedPr = $pullRequest[0]
        $prNumber = [int]$selectedPr.number
        $prState = "$($selectedPr.state)".ToUpperInvariant()
        $prUrl = $selectedPr.url
        if ($selectedPr.PSObject.Properties.Name -contains 'headRefOid' -and $selectedPr.headRefOid) {
            $prCoversHead = $selectedPr.headRefOid -eq $worktree.Head
        }
    }

    $lastActivity = $null
    $recentActivity = $false
    if ($activity.ContainsKey($path)) {
        $lastActivity = $activity[$path].ToUniversalTime()
        $recentActivity = ($now - $lastActivity).TotalDays -le $RecentActivityDays
    }

    $mergedState = if ($mergedLocally) {
        'reachable-from-base'
    }
    elseif ($prState -eq 'MERGED' -and $prCoversHead) {
        'merged-pr-covers-head'
    }
    else {
        'no'
    }

    $bucket = if ($trackedCount -gt 0) {
        'hold-wip'
    }
    elseif ($prState -eq 'OPEN') {
        'hold-open-pr'
    }
    elseif ($worktree.Locked) {
        'hold-locked'
    }
    elseif ($hiddenIndexFlagCount -gt 0) {
        'review-index-flags'
    }
    elseif ($untrackedCount -gt 0) {
        'review-scratch'
    }
    elseif ($recentActivity) {
        'verify-recent-activity'
    }
    elseif ($pullRequestLookup.Status -eq 'unavailable') {
        'review-pr-unknown'
    }
    elseif ($mergedState -ne 'no') {
        'safe-merged'
    }
    elseif ($prState -eq 'CLOSED') {
        'review-closed-pr'
    }
    elseif ($remoteState -in 'detached', 'remote-unknown', 'unpushed' -or
        $remoteState.StartsWith('ahead:') -or $remoteState.StartsWith('diverged:')) {
        'review-unpublished'
    }
    else {
        'review'
    }

    $sizeBytes = $null
    $sizeComplete = $null
    if ($IncludeSize) {
        $sizeResult = Get-DirectorySize -Path $path
        $sizeBytes = $sizeResult.SizeBytes
        $sizeComplete = $sizeResult.SizeComplete
    }

    $results.Add([pscustomobject]@{
        Worktree          = $path
        Branch            = $worktree.Branch
        Head              = $worktree.Head
        AgeDays           = $ageDays
        SizeBytes         = $sizeBytes
        SizeComplete      = $sizeComplete
        Dirty             = $dirtyState
        AssumeUnchanged   = $assumeUnchangedCount
        SkipWorktree      = $skipWorktreeCount
        RemoteState       = $remoteState
        BaseRef           = $baseRef
        BaseRefAgeDays    = $baseAgeDays
        MergeState        = $mergedState
        PullRequestNumber = $prNumber
        PullRequestState  = $prState
        PullRequestLookup = $pullRequestLookup.Status
        PullRequestUrl    = $prUrl
        PullRequestAtHead = $prCoversHead
        LastActivityUtc   = $lastActivity
        Locked            = $worktree.Locked
        Prunable          = $worktree.Prunable
        Note              = $worktree.Reason
        Bucket            = $bucket
    })
}

$ordered = @($results | Sort-Object @{
    Expression = {
        switch ($_.Bucket) {
            'hold-wip' { 0 }
            'hold-open-pr' { 1 }
            'hold-locked' { 2 }
            'verify-recent-activity' { 3 }
            'review-prunable' { 4 }
            'review-index-flags' { 5 }
            'review-pr-unknown' { 6 }
            'review-scratch' { 7 }
            'review-closed-pr' { 8 }
            'review-unpublished' { 9 }
            'review' { 10 }
            'safe-merged' { 11 }
            default { 12 }
        }
    }
}, @{ Expression = 'SizeBytes'; Descending = $true }, 'Worktree')

if ($AsJson) {
    ConvertTo-Json -InputObject @($ordered) -Depth 5
}
else {
    $ordered
}
