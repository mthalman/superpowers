<#
.SYNOPSIS
    Checks out a PR locally so its changes can be reviewed against the base branch.
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
.PARAMETER BaseRef
    Base branch name (used for Azure DevOps fallback fetch)
.PARAMETER HeadRef
    Head branch name (used for Azure DevOps fallback fetch)
.OUTPUTS
    JSON object: { success, message }
#>
param(
    [Parameter(Mandatory)][string]$Platform,
    [Parameter(Mandatory)][string]$Org,
    [Parameter(Mandatory)][string]$Repo,
    [Parameter(Mandatory)][int]$PrNumber,
    [string]$Project,
    [string]$BaseRef,
    [string]$HeadRef
)

$ErrorActionPreference = 'Stop'

if ($Platform -eq 'github') {
    $output = gh pr checkout $PrNumber --repo "$Org/$Repo" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to checkout GitHub PR: $output"
        exit 1
    }

    @{ success = $true; message = "Checked out PR #$PrNumber" } | ConvertTo-Json -Compress
}
elseif ($Platform -eq 'azuredevops') {
    # Ensure base branch is fetched for diff comparison
    git fetch origin "$BaseRef" 2>&1 | Out-Null

    # Try fetching the PR source branch
    $fetched = $false
    if ($HeadRef) {
        $headFetchOutput = git fetch origin "$HeadRef" 2>&1
        if ($LASTEXITCODE -eq 0) {
            git checkout "origin/$HeadRef" -B "pr-$PrNumber" 2>&1 | Out-Null
            $fetched = $true
        }
    }

    if (-not $fetched) {
        # Try Azure DevOps PR ref format
        $prRefOutput = git fetch origin "+refs/pull/$PrNumber/merge:pr-$PrNumber" 2>&1
        if ($LASTEXITCODE -eq 0) {
            git checkout "pr-$PrNumber" 2>&1 | Out-Null
            $fetched = $true
        }
    }

    if (-not $fetched) {
        $detail = if ($HeadRef) { "Tried branch '$HeadRef' and PR ref 'refs/pull/$PrNumber/merge'." } else { "Tried PR ref 'refs/pull/$PrNumber/merge' (no HeadRef provided)." }
        Write-Error "Failed to fetch and checkout PR #$PrNumber. $detail Ensure the branch exists and you have access."
        exit 1
    }

    @{ success = $true; message = "Checked out PR #$PrNumber to branch pr-$PrNumber" } | ConvertTo-Json -Compress
}
else {
    Write-Error "Unknown platform: $Platform. Expected 'github' or 'azuredevops'."
    exit 1
}
