<#
.SYNOPSIS
    Fetches PR metadata including title, description, comments, and review activity.
.PARAMETER Platform
    "github" or "azuredevops"
.PARAMETER Org
    Organization or owner name
.PARAMETER Repo
    Repository name
.PARAMETER PrNumber
    Pull request number
.PARAMETER Project
    Azure DevOps project name (required for azuredevops platform)
.OUTPUTS
    JSON with PR details: title, body, author, state, refs, comments, reviews
#>
param(
    [Parameter(Mandatory)][string]$Platform,
    [Parameter(Mandatory)][string]$Org,
    [Parameter(Mandatory)][string]$Repo,
    [Parameter(Mandatory)][int]$PrNumber,
    [string]$Project
)

$ErrorActionPreference = 'Stop'

if ($Platform -eq 'github') {
    # Note: baseRefOid is not a supported field in gh pr view --json;
    # fetch it separately via the REST API.
    $fields = @(
        'title', 'body', 'comments', 'reviews', 'labels',
        'headRefName', 'baseRefName', 'headRefOid',
        'files', 'state', 'author', 'url'
    ) -join ','

    $prJson = gh pr view $PrNumber --repo "$Org/$Repo" --json $fields 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to fetch GitHub PR: $prJson"
        exit 1
    }

    $pr = $prJson | ConvertFrom-Json

    # Resolve baseRefOid via the REST API (no local git repo required).
    # This is needed because gh pr view --json does not support baseRefOid.
    $baseRefOid = gh api "repos/$Org/$Repo/pulls/$PrNumber" --jq '.base.sha' 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Could not resolve baseRefOid via REST API: $baseRefOid. Diff may use branch name instead of exact commit."
        $baseRefOid = $null
    }

    $pr | Add-Member -NotePropertyName 'baseRefOid' -NotePropertyValue $baseRefOid
    $pr | ConvertTo-Json -Depth 10
}
elseif ($Platform -eq 'azuredevops') {
    if (-not $Project) {
        Write-Error "Project parameter is required for Azure DevOps PRs"
        exit 1
    }

    $orgUrl = "https://dev.azure.com/$Org"

    $prDetails = az repos pr show --id $PrNumber --org $orgUrl --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to fetch Azure DevOps PR: $prDetails"
        exit 1
    }

    $pr = $prDetails | ConvertFrom-Json
    $repoId = $pr.repository.id

    # Fetch review threads (comments)
    $threads = $null
    $threadsOutput = az devops invoke --area git --resource threads `
        --route-parameters project="$Project" repositoryId="$repoId" pullRequestId=$PrNumber `
        --http-method GET --org $orgUrl --api-version 7.1 --output json 2>&1

    if ($LASTEXITCODE -eq 0) {
        $threads = ($threadsOutput | ConvertFrom-Json).value
    }
    else {
        $threads = @()
    }

    $result = @{
        title       = $pr.title
        body        = $pr.description
        author      = $pr.createdBy.displayName
        state       = $pr.status
        baseRefName = $pr.targetRefName -replace '^refs/heads/', ''
        headRefName = $pr.sourceRefName -replace '^refs/heads/', ''
        baseRefOid  = $pr.lastMergeTargetCommit.commitId
        headRefOid  = $pr.lastMergeSourceCommit.commitId
        url         = "$orgUrl/$Project/_git/$Repo/pullrequest/$PrNumber"
        reviewers   = @($pr.reviewers | ForEach-Object { @{ name = $_.displayName; vote = $_.vote } })
        threads     = $threads
    }

    $result | ConvertTo-Json -Depth 10
}
else {
    Write-Error "Unknown platform: $Platform. Expected 'github' or 'azuredevops'."
    exit 1
}
