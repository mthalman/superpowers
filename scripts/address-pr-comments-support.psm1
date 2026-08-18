Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-AddressPrPropertyValue {
    param(
        [Parameter(Mandatory)] [object] $InputObject,
        [Parameter(Mandatory)] [string[]] $Names,
        [object] $Default = $null
    )

    foreach ($name in $Names) {
        $property = $InputObject.PSObject.Properties[$name]
        if ($null -ne $property) {
            return $property.Value
        }
    }

    return $Default
}

function ConvertTo-AddressPrDateTimeOffset {
    param([object] $Value)

    if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string] $Value)) {
        return $null
    }

    if ($Value -is [DateTimeOffset]) {
        return $Value.ToUniversalTime()
    }

    if ($Value -is [DateTime]) {
        $dateTime = [DateTime] $Value
        if ($dateTime.Kind -eq [DateTimeKind]::Unspecified) {
            $dateTime = [DateTime]::SpecifyKind($dateTime, [DateTimeKind]::Utc)
        }
        return [DateTimeOffset] $dateTime.ToUniversalTime()
    }

    return [DateTimeOffset]::Parse(
        [string] $Value,
        [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::AssumeUniversal -bor
            [Globalization.DateTimeStyles]::AdjustToUniversal
    )
}

function ConvertTo-AddressPrIsoTimestamp {
    param([object] $Value)

    $timestamp = ConvertTo-AddressPrDateTimeOffset $Value
    if ($null -eq $timestamp) {
        return $null
    }

    return $timestamp.UtcDateTime.ToString('o')
}

function ConvertTo-AddressPrSafeKey {
    param([Parameter(Mandatory)] [string] $Value)

    return [regex]::Replace($Value, '[^A-Za-z0-9._-]', '-')
}

function Remove-AddressPrRemoteCredentials {
    param([Parameter(Mandatory)] [string] $RemoteUrl)

    return [regex]::Replace($RemoteUrl, '^(https?://)[^/]+@', '$1')
}

function Resolve-AddressPrRemote {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $RemoteName,
        [Parameter(Mandatory)] [string] $RemoteUrl
    )

    $trimmedUrl = $RemoteUrl.Trim()
    $redactedUrl = Remove-AddressPrRemoteCredentials $trimmedUrl
    $matches = $null

    if ($redactedUrl -match '^(?:https?://)dev\.azure\.com/(?<org>[^/]+)/(?<project>[^/]+)/_git/(?<repo>[^/?#]+?)(?:\.git)?/?$') {
        $matches = $Matches
    }
    elseif ($redactedUrl -match '^(?:https?://)(?<org>[^./]+)\.visualstudio\.com/(?<project>[^/]+)/_git/(?<repo>[^/?#]+?)(?:\.git)?/?$') {
        $matches = $Matches
    }
    elseif ($redactedUrl -match '^(?:(?:ssh://)?git@ssh\.dev\.azure\.com[:/]v3/)(?<org>[^/]+)/(?<project>[^/]+)/(?<repo>[^/?#]+?)(?:\.git)?/?$') {
        $matches = $Matches
    }

    if ($null -ne $matches) {
        return [pscustomobject]@{
            Provider     = 'azure-devops'
            Organization = [Uri]::UnescapeDataString($matches.org)
            Project      = [Uri]::UnescapeDataString($matches.project)
            Repository   = [Uri]::UnescapeDataString($matches.repo)
            RemoteName   = $RemoteName
            RemoteUrl    = $redactedUrl
        }
    }

    if ($redactedUrl -match '^(?:https?://)github\.com/(?<org>[^/]+)/(?<repo>[^/?#]+?)(?:\.git)?/?$' -or
        $redactedUrl -match '^(?:ssh://)?git@github\.com[:/](?<org>[^/]+)/(?<repo>[^/?#]+?)(?:\.git)?/?$') {
        return [pscustomobject]@{
            Provider     = 'github'
            Organization = [Uri]::UnescapeDataString($Matches.org)
            Project      = $null
            Repository   = [Uri]::UnescapeDataString($Matches.repo)
            RemoteName   = $RemoteName
            RemoteUrl    = $redactedUrl
        }
    }

    throw "Unsupported git remote URL '$redactedUrl'. Expected a GitHub or Azure DevOps repository URL."
}

function ConvertFrom-AzureDevOpsPullRequestUrl {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string] $Url)

    $patterns = @(
        '^https?://dev\.azure\.com/(?<org>[^/]+)/(?<project>[^/]+)/_git/(?<repo>[^/]+)/pullrequest/(?<pr>\d+)(?:[?#].*)?$',
        '^https?://(?<org>[^./]+)\.visualstudio\.com/(?<project>[^/]+)/_git/(?<repo>[^/]+)/pullrequest/(?<pr>\d+)(?:[?#].*)?$'
    )

    foreach ($pattern in $patterns) {
        if ($Url -match $pattern) {
            return [pscustomobject]@{
                Provider      = 'azure-devops'
                Organization  = [Uri]::UnescapeDataString($Matches.org)
                Project       = [Uri]::UnescapeDataString($Matches.project)
                Repository    = [Uri]::UnescapeDataString($Matches.repo)
                PullRequestId = [int] $Matches.pr
            }
        }
    }

    throw "Invalid Azure DevOps pull request URL '$Url'."
}

function New-AddressPrPullRequestUrl {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [object] $Metadata)

    $provider = [string] (Get-AddressPrPropertyValue -InputObject $Metadata -Names 'provider', 'Provider')
    $organization = [Uri]::EscapeDataString([string] (Get-AddressPrPropertyValue -InputObject $Metadata -Names 'organization', 'Organization'))
    $repository = [Uri]::EscapeDataString([string] (Get-AddressPrPropertyValue -InputObject $Metadata -Names 'repository', 'Repository'))
    $prNumber = Get-AddressPrPropertyValue -InputObject $Metadata -Names 'pr_number', 'PullRequestId', 'PrNumber'

    switch ($provider.ToLowerInvariant()) {
        'github' {
            return "https://github.com/$organization/$repository/pull/$prNumber"
        }
        'azure-devops' {
            $project = [Uri]::EscapeDataString([string] (Get-AddressPrPropertyValue -InputObject $Metadata -Names 'project', 'Project'))
            return "https://dev.azure.com/$organization/$project/_git/$repository/pullrequest/$prNumber"
        }
        default {
            throw "Unsupported pull request provider '$provider'."
        }
    }
}

function New-AddressPrThreadUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [object] $Metadata,
        [Parameter(Mandatory)] [string] $ThreadId
    )

    $provider = [string] (Get-AddressPrPropertyValue -InputObject $Metadata -Names 'provider', 'Provider')
    $prUrl = New-AddressPrPullRequestUrl -Metadata $Metadata

    switch ($provider.ToLowerInvariant()) {
        'github' { return "$prUrl#discussion_r$ThreadId" }
        'azure-devops' { return "${prUrl}?discussionId=$ThreadId" }
        default { throw "Unsupported pull request provider '$provider'." }
    }
}

function New-AddressPrCommitUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [object] $Metadata,
        [Parameter(Mandatory)] [string] $CommitSha
    )

    $provider = [string] (Get-AddressPrPropertyValue -InputObject $Metadata -Names 'provider', 'Provider')
    $organization = [Uri]::EscapeDataString([string] (Get-AddressPrPropertyValue -InputObject $Metadata -Names 'organization', 'Organization'))
    $repository = [Uri]::EscapeDataString([string] (Get-AddressPrPropertyValue -InputObject $Metadata -Names 'repository', 'Repository'))

    switch ($provider.ToLowerInvariant()) {
        'github' {
            return "https://github.com/$organization/$repository/commit/$CommitSha"
        }
        'azure-devops' {
            $project = [Uri]::EscapeDataString([string] (Get-AddressPrPropertyValue -InputObject $Metadata -Names 'project', 'Project'))
            return "https://dev.azure.com/$organization/$project/_git/$repository/commit/$CommitSha"
        }
        default {
            throw "Unsupported pull request provider '$provider'."
        }
    }
}

function Test-AddressPrThreadUnresolved {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [ValidateSet('github', 'azure-devops')] [string] $Provider,
        [Parameter(Mandatory)] [object] $Thread
    )

    if ($Provider -eq 'github') {
        $position = Get-AddressPrPropertyValue -InputObject $Thread -Names 'position'
        $isResolved = [bool] (Get-AddressPrPropertyValue -InputObject $Thread -Names 'isResolved', 'is_resolved' -Default $false)
        return $null -ne $position -and -not $isResolved
    }

    $rawStatus = Get-AddressPrPropertyValue -InputObject $Thread -Names 'status'
    if ($null -eq $rawStatus -or [string]::IsNullOrWhiteSpace([string] $rawStatus)) {
        $comments = @(Get-AddressPrPropertyValue -InputObject $Thread -Names 'comments' -Default @())
        $nonSystemComments = @($comments | Where-Object {
            $commentType = Get-AddressPrPropertyValue -InputObject $_ -Names 'commentType'
            $commentType -ne 3 -and ([string] $commentType).ToLowerInvariant() -ne 'system'
        })
        if ($comments.Count -gt 0 -and $nonSystemComments.Count -eq 0) {
            return $false
        }
    }

    if ($rawStatus -is [byte] -or
        $rawStatus -is [int16] -or
        $rawStatus -is [int32] -or
        $rawStatus -is [int64]) {
        $numericStatus = [int] $rawStatus
        $statusMap = @{
            0 = 'unknown'
            1 = 'active'
            2 = 'fixed'
            3 = 'wontFix'
            4 = 'closed'
            5 = 'byDesign'
            6 = 'pending'
        }
        if (-not $statusMap.ContainsKey($numericStatus)) {
            throw "Unknown Azure DevOps thread status '$numericStatus'."
        }
        $rawStatus = $statusMap[$numericStatus]
    }

    $status = ([string] $rawStatus).ToLowerInvariant()
    switch ($status) {
        'unknown' { return $false }
        'active' { return $true }
        'pending' { return $true }
        'fixed' { return $false }
        'wontfix' { return $false }
        'closed' { return $false }
        'bydesign' { return $false }
        default { throw "Unknown Azure DevOps thread status '$rawStatus'." }
    }
}

function ConvertFrom-AzureDevOpsThread {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [object] $Thread)

    $comments = @(Get-AddressPrPropertyValue -InputObject $Thread -Names 'comments' -Default @())
    $comments = @($comments | Sort-Object `
        @{ Expression = {
            $timestamp = Get-AddressPrPropertyValue -InputObject $_ -Names 'publishedDate', 'lastUpdatedDate'
            $normalizedTimestamp = ConvertTo-AddressPrDateTimeOffset $timestamp
            if ($null -ne $normalizedTimestamp) { $normalizedTimestamp }
            else { [DateTimeOffset]::MinValue }
        } }, `
        @{ Expression = { [int] (Get-AddressPrPropertyValue -InputObject $_ -Names 'id' -Default 0) } })
    $rootComment = $comments |
        Where-Object {
            $parentId = Get-AddressPrPropertyValue -InputObject $_ -Names 'parentCommentId' -Default -1
            [int] $parentId -eq 0
        } |
        Select-Object -First 1

    $remoteUnresolved = Test-AddressPrThreadUnresolved -Provider azure-devops -Thread $Thread
    if ($remoteUnresolved -and $null -eq $rootComment) {
        $threadId = Get-AddressPrPropertyValue -InputObject $Thread -Names 'id'
        throw "Azure DevOps thread '$threadId' does not contain a root comment with parentCommentId 0."
    }

    $conversation = foreach ($comment in $comments) {
        $author = Get-AddressPrPropertyValue -InputObject $comment -Names 'author'
        [pscustomobject]@{
            id                = [string] (Get-AddressPrPropertyValue -InputObject $comment -Names 'id')
            parent_comment_id = [string] (Get-AddressPrPropertyValue -InputObject $comment -Names 'parentCommentId')
            author            = if ($null -eq $author) {
                $null
            }
            else {
                Get-AddressPrPropertyValue -InputObject $author -Names 'displayName', 'uniqueName'
            }
            content           = Get-AddressPrPropertyValue -InputObject $comment -Names 'content'
            published_date    = ConvertTo-AddressPrIsoTimestamp (
                Get-AddressPrPropertyValue -InputObject $comment -Names 'publishedDate'
            )
            last_updated_date = ConvertTo-AddressPrIsoTimestamp (
                Get-AddressPrPropertyValue -InputObject $comment -Names 'lastUpdatedDate'
            )
            comment_type      = Get-AddressPrPropertyValue -InputObject $comment -Names 'commentType'
            is_deleted        = [bool] (Get-AddressPrPropertyValue -InputObject $comment -Names 'isDeleted' -Default $false)
        }
    }

    $timestamps = foreach ($comment in $conversation) {
        if ($comment.last_updated_date) { $comment.last_updated_date }
        elseif ($comment.published_date) { $comment.published_date }
    }
    $latestTimestamp = $timestamps |
        Sort-Object { [DateTimeOffset]::Parse($_) } -Descending |
        Select-Object -First 1
    if (-not $latestTimestamp) {
        $latestTimestamp = ConvertTo-AddressPrIsoTimestamp (
            Get-AddressPrPropertyValue -InputObject $Thread -Names 'lastUpdatedDate', 'publishedDate'
        )
    }

    $context = Get-AddressPrPropertyValue -InputObject $Thread -Names 'threadContext'
    $file = $null
    $line = $null
    if ($null -ne $context) {
        $filePath = Get-AddressPrPropertyValue -InputObject $context -Names 'filePath'
        if ($filePath) {
            $file = ([string] $filePath).TrimStart('/')
        }
        $rightStart = Get-AddressPrPropertyValue -InputObject $context -Names 'rightFileStart'
        $leftStart = Get-AddressPrPropertyValue -InputObject $context -Names 'leftFileStart'
        $selectedStart = if ($null -ne $rightStart) { $rightStart } else { $leftStart }
        if ($null -ne $selectedStart) {
            $line = Get-AddressPrPropertyValue -InputObject $selectedStart -Names 'line'
        }
    }

    $threadId = [string] (Get-AddressPrPropertyValue -InputObject $Thread -Names 'id')
    $rootCommentId = if ($null -eq $rootComment) {
        $null
    }
    else {
        [string] (Get-AddressPrPropertyValue -InputObject $rootComment -Names 'id')
    }

    return [pscustomobject]@{
        id                    = $threadId
        provider              = 'azure-devops'
        thread_id             = $threadId
        root_comment_id       = $rootCommentId
        file                  = $file
        line                  = $line
        status                = if ($remoteUnresolved) { 'pending' } else { 'completed' }
        remote_unresolved     = $remoteUnresolved
        commit_sha            = $null
        action                = $null
        pending_replies       = @()
        conversation          = @($conversation)
        latest_post_timestamp = $latestTimestamp
        last_post_timestamp   = $latestTimestamp
        provider_metadata     = [pscustomobject]@{
            status            = Get-AddressPrPropertyValue -InputObject $Thread -Names 'status'
            published_date    = ConvertTo-AddressPrIsoTimestamp (
                Get-AddressPrPropertyValue -InputObject $Thread -Names 'publishedDate'
            )
            last_updated_date = ConvertTo-AddressPrIsoTimestamp (
                Get-AddressPrPropertyValue -InputObject $Thread -Names 'lastUpdatedDate'
            )
            properties        = Get-AddressPrPropertyValue -InputObject $Thread -Names 'properties'
        }
    }
}

function Get-AddressPrProgressRelativePath {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [object] $Metadata)

    $provider = [string] (Get-AddressPrPropertyValue -InputObject $Metadata -Names 'provider', 'Provider')
    $organization = ConvertTo-AddressPrSafeKey (
        [string] (Get-AddressPrPropertyValue -InputObject $Metadata -Names 'organization', 'Organization')
    )
    $repository = ConvertTo-AddressPrSafeKey (
        [string] (Get-AddressPrPropertyValue -InputObject $Metadata -Names 'repository', 'Repository')
    )
    $prNumber = Get-AddressPrPropertyValue -InputObject $Metadata -Names 'pr_number', 'PullRequestId', 'PrNumber'

    if ($provider -eq 'github') {
        return "address-pr-comments/$organization-$repository/pr-$prNumber.json"
    }
    if ($provider -eq 'azure-devops') {
        $project = ConvertTo-AddressPrSafeKey (
            [string] (Get-AddressPrPropertyValue -InputObject $Metadata -Names 'project', 'Project')
        )
        return "address-pr-comments/azure-devops/$organization-$project-$repository/pr-$prNumber.json"
    }

    throw "Unsupported pull request provider '$provider'."
}

function ConvertTo-AddressPrCommentState {
    param(
        [Parameter(Mandatory)] [object] $Comment,
        [Parameter(Mandatory)] [string] $Provider
    )

    $data = [ordered]@{}
    foreach ($property in $Comment.PSObject.Properties) {
        $data[$property.Name] = $property.Value
    }

    $id = [string] (Get-AddressPrPropertyValue -InputObject $Comment -Names 'id', 'thread_id')
    $data.id = $id
    $data.provider = $Provider
    if (-not $data.Contains('thread_id')) { $data.thread_id = $id }
    if (-not $data.Contains('root_comment_id')) { $data.root_comment_id = $id }
    if (-not $data.Contains('status')) { $data.status = 'pending' }
    if (-not $data.Contains('commit_sha')) { $data.commit_sha = $null }
    if (-not $data.Contains('action')) { $data.action = $null }
    $pendingReplies = Get-AddressPrPropertyValue -InputObject $Comment -Names 'pending_replies' -Default @()
    $data.pending_replies = @($pendingReplies)
    if (-not $data.Contains('last_post_timestamp')) {
        $data.last_post_timestamp = ConvertTo-AddressPrIsoTimestamp (
            Get-AddressPrPropertyValue -InputObject $Comment -Names 'latest_post_timestamp'
        )
    }
    elseif ($data.last_post_timestamp) {
        $data.last_post_timestamp = ConvertTo-AddressPrIsoTimestamp $data.last_post_timestamp
    }

    return [pscustomobject] $data
}

function Get-AddressPrCommentKey {
    param(
        [Parameter(Mandatory)] [object] $Comment,
        [Parameter(Mandatory)] [string] $Provider
    )

    if ($Provider -eq 'github') {
        $rootCommentId = Get-AddressPrPropertyValue -InputObject $Comment -Names 'root_comment_id', 'id'
        return [string] $rootCommentId
    }

    return [string] (Get-AddressPrPropertyValue -InputObject $Comment -Names 'thread_id', 'id')
}

function Merge-AddressPrProgress {
    [CmdletBinding()]
    param(
        [object] $Existing,
        [Parameter(Mandatory)] [object] $Metadata,
        [object[]] $FreshComments = @()
    )

    $provider = [string] (Get-AddressPrPropertyValue -InputObject $Metadata -Names 'provider', 'Provider')
    $resultData = [ordered]@{}
    if ($null -ne $Existing) {
        foreach ($property in $Existing.PSObject.Properties) {
            $resultData[$property.Name] = $property.Value
        }
    }

    $resultData.schema_version = 2
    foreach ($field in @(
        'provider',
        'organization',
        'project',
        'repository',
        'repository_id',
        'pr_number',
        'branch',
        'source_branch',
        'source_repository',
        'source_repository_owner',
        'remote_name',
        'remote_url'
    )) {
        $pascalName = ($field -split '_' | ForEach-Object {
            if ($_.Length -eq 0) { return }
            $_.Substring(0, 1).ToUpperInvariant() + $_.Substring(1)
        }) -join ''
        $candidateNames = @($field, $pascalName)
        if ($field -eq 'pr_number') {
            $candidateNames += 'PullRequestId'
        }
        $resultData[$field] = Get-AddressPrPropertyValue -InputObject $Metadata -Names $candidateNames
    }
    $resultData.provider = $provider
    $prUrl = Get-AddressPrPropertyValue -InputObject $Metadata -Names 'pr_url', 'PrUrl'
    if (-not $prUrl) {
        $prUrl = New-AddressPrPullRequestUrl -Metadata $Metadata
    }
    $resultData.pr_url = $prUrl
    $resultData.last_updated = [DateTime]::UtcNow.ToString('o')

    $existingById = @{}
    $existingOrder = New-Object System.Collections.Generic.List[string]
    if ($null -ne $Existing) {
        $existingComments = @(Get-AddressPrPropertyValue -InputObject $Existing -Names 'comments' -Default @())
        foreach ($comment in $existingComments) {
            $normalized = ConvertTo-AddressPrCommentState -Comment $comment -Provider $provider
            $key = Get-AddressPrCommentKey -Comment $normalized -Provider $provider
            $existingById[$key] = $normalized
            $existingOrder.Add($key)
        }
    }

    $mergedComments = New-Object System.Collections.Generic.List[object]
    $freshIds = @{}
    foreach ($freshComment in @($FreshComments)) {
        $fresh = ConvertTo-AddressPrCommentState -Comment $freshComment -Provider $provider
        $key = Get-AddressPrCommentKey -Comment $fresh -Provider $provider
        $freshIds[$key] = $true

        if ($existingById.ContainsKey($key)) {
            $old = $existingById[$key]
            $mergedData = [ordered]@{}
            foreach ($property in $old.PSObject.Properties) {
                $mergedData[$property.Name] = $property.Value
            }
            foreach ($property in $fresh.PSObject.Properties) {
                if ($property.Name -notin @('status', 'action', 'commit_sha', 'pending_replies')) {
                    $mergedData[$property.Name] = $property.Value
                }
            }

            $oldTimestamp = ConvertTo-AddressPrIsoTimestamp (
                Get-AddressPrPropertyValue -InputObject $old -Names 'last_post_timestamp'
            )
            $latestTimestamp = ConvertTo-AddressPrIsoTimestamp (
                Get-AddressPrPropertyValue -InputObject $fresh -Names 'latest_post_timestamp', 'last_post_timestamp'
            )
            if ($latestTimestamp) {
                $mergedData.last_post_timestamp = $latestTimestamp
                if (-not $oldTimestamp -or
                    [DateTimeOffset]::Parse($latestTimestamp) -gt [DateTimeOffset]::Parse($oldTimestamp)) {
                    $mergedData.status = 'pending'
                }
                elseif ($null -ne $fresh.PSObject.Properties['remote_unresolved'] -and
                    -not [bool] $fresh.remote_unresolved) {
                    $mergedData.status = 'completed'
                }
            }
            elseif ($null -ne $fresh.PSObject.Properties['remote_unresolved'] -and
                -not [bool] $fresh.remote_unresolved) {
                $mergedData.status = 'completed'
            }

            $mergedComments.Add([pscustomobject] $mergedData)
        }
        else {
            $mergedComments.Add($fresh)
        }
    }

    foreach ($key in $existingOrder) {
        if (-not $freshIds.ContainsKey($key)) {
            $mergedComments.Add($existingById[$key])
        }
    }

    $resultData.comments = $mergedComments.ToArray()
    return [pscustomobject] $resultData
}

function New-AddressPrFixedReply {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [object] $Metadata,
        [Parameter(Mandatory)] [string] $CommitSha,
        [scriptblock] $ResolveCommitSha
    )

    $provider = [string] (Get-AddressPrPropertyValue -InputObject $Metadata -Names 'provider', 'Provider')
    if ($provider -eq 'github') {
        return "Fixed in $CommitSha"
    }
    if ($provider -ne 'azure-devops') {
        throw "Unsupported pull request provider '$provider'."
    }

    $fullSha = $CommitSha
    if ($CommitSha -notmatch '^[0-9a-fA-F]{40}$') {
        if ($null -ne $ResolveCommitSha) {
            $fullSha = & $ResolveCommitSha $CommitSha
        }
        else {
            $fullSha = (& git rev-parse "$CommitSha^{commit}" 2>$null).Trim()
            if ($LASTEXITCODE -ne 0) {
                throw "Could not resolve commit '$CommitSha' to a full SHA."
            }
        }
    }
    if ([string] $fullSha -notmatch '^[0-9a-fA-F]{40}$') {
        throw "Commit '$CommitSha' did not resolve to a full 40-character SHA."
    }

    $displaySha = if ($CommitSha.Length -le 12) { $CommitSha } else { $CommitSha.Substring(0, 7) }
    $commitUrl = New-AddressPrCommitUrl -Metadata $Metadata -CommitSha $fullSha
    return "Fixed in [$displaySha]($commitUrl)"
}

function Write-AzureDevOpsReplyPayload {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Content,
        [Parameter(Mandatory)] [int] $RootCommentId
    )

    $payload = [ordered]@{
        content         = $Content
        parentCommentId = $RootCommentId
        commentType     = 1
    }
    $json = $payload | ConvertTo-Json -Compress
    [IO.File]::WriteAllText($Path, $json, [Text.UTF8Encoding]::new($false))
}

function New-AzureDevOpsThreadListInvokeArguments {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [object] $Metadata)

    $project = Get-AddressPrPropertyValue -InputObject $Metadata -Names 'project', 'Project'
    $repositoryId = Get-AddressPrPropertyValue -InputObject $Metadata -Names 'repository_id', 'RepositoryId'
    $prNumber = Get-AddressPrPropertyValue -InputObject $Metadata -Names 'pr_number', 'PullRequestId', 'PrNumber'
    $organization = [Uri]::EscapeDataString([string] (
        Get-AddressPrPropertyValue -InputObject $Metadata -Names 'organization', 'Organization'
    ))

    return @(
        'devops', 'invoke',
        '--organization', "https://dev.azure.com/$organization",
        '--area', 'git',
        '--resource', 'pullRequestThreads',
        '--route-parameters',
        "project=$project",
        "repositoryId=$repositoryId",
        "pullRequestId=$prNumber",
        '--api-version', '7.1',
        '--output', 'json',
        '--only-show-errors'
    )
}

function New-AzureDevOpsReplyInvokeArguments {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [object] $Metadata,
        [Parameter(Mandatory)] [string] $ThreadId,
        [Parameter(Mandatory)] [string] $PayloadPath
    )

    $project = Get-AddressPrPropertyValue -InputObject $Metadata -Names 'project', 'Project'
    $repositoryId = Get-AddressPrPropertyValue -InputObject $Metadata -Names 'repository_id', 'RepositoryId'
    $prNumber = Get-AddressPrPropertyValue -InputObject $Metadata -Names 'pr_number', 'PullRequestId', 'PrNumber'
    $organization = [Uri]::EscapeDataString([string] (
        Get-AddressPrPropertyValue -InputObject $Metadata -Names 'organization', 'Organization'
    ))

    return @(
        'devops', 'invoke',
        '--organization', "https://dev.azure.com/$organization",
        '--area', 'git',
        '--resource', 'pullRequestThreadComments',
        '--route-parameters',
        "project=$project",
        "repositoryId=$repositoryId",
        "pullRequestId=$prNumber",
        "threadId=$ThreadId",
        '--api-version', '7.1',
        '--http-method', 'POST',
        '--in-file', $PayloadPath,
        '--encoding', 'utf-8',
        '--output', 'json',
        '--only-show-errors'
    )
}

function Invoke-AddressPrPendingReplies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [object] $Progress,
        [Parameter(Mandatory)] [scriptblock] $PostReply,
        [Parameter(Mandatory)] [scriptblock] $SaveProgress
    )

    $postedCount = 0
    $failures = New-Object System.Collections.Generic.List[object]
    $comments = @(Get-AddressPrPropertyValue -InputObject $Progress -Names 'comments' -Default @())

    foreach ($comment in $comments) {
        $replies = @(Get-AddressPrPropertyValue -InputObject $comment -Names 'pending_replies' -Default @())
        foreach ($reply in $replies) {
            try {
                $response = & $PostReply $comment $reply
                $responseId = if ($null -eq $response) {
                    $null
                }
                else {
                    Get-AddressPrPropertyValue -InputObject $response -Names 'id'
                }
                if ($null -eq $responseId -or [string]::IsNullOrWhiteSpace([string] $responseId)) {
                    throw 'Reply API response did not include a comment ID.'
                }
            }
            catch {
                $failures.Add([pscustomobject]@{
                    CommentId = [string] (Get-AddressPrPropertyValue -InputObject $comment -Names 'id')
                    ThreadId  = [string] (Get-AddressPrPropertyValue -InputObject $comment -Names 'thread_id', 'id')
                    Reply     = $reply
                    Error     = $_.Exception.Message
                })
                break
            }

            $currentReplies = @(Get-AddressPrPropertyValue -InputObject $comment -Names 'pending_replies' -Default @())
            if ($currentReplies.Count -le 1) {
                $comment.pending_replies = @()
            }
            else {
                $comment.pending_replies = @($currentReplies[1..($currentReplies.Count - 1)])
            }

            $publishedDate = Get-AddressPrPropertyValue `
                -InputObject $response `
                -Names 'publishedDate', 'created_at', 'createdAt'
            if ($publishedDate) {
                $comment.last_post_timestamp = ConvertTo-AddressPrIsoTimestamp $publishedDate
            }

            try {
                $null = & $SaveProgress $Progress
            }
            catch {
                throw "Reply $responseId was posted, but progress could not be persisted: $($_.Exception.Message)"
            }
            $postedCount++
        }
    }

    return [pscustomobject]@{
        PostedCount = $postedCount
        Failures    = $failures.ToArray()
    }
}

Export-ModuleMember -Function @(
    'Resolve-AddressPrRemote',
    'ConvertFrom-AzureDevOpsPullRequestUrl',
    'New-AddressPrPullRequestUrl',
    'New-AddressPrThreadUrl',
    'New-AddressPrCommitUrl',
    'Test-AddressPrThreadUnresolved',
    'ConvertFrom-AzureDevOpsThread',
    'Get-AddressPrProgressRelativePath',
    'Merge-AddressPrProgress',
    'New-AddressPrFixedReply',
    'Write-AzureDevOpsReplyPayload',
    'New-AzureDevOpsThreadListInvokeArguments',
    'New-AzureDevOpsReplyInvokeArguments',
    'Invoke-AddressPrPendingReplies'
)
