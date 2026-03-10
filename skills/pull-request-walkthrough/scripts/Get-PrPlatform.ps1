<#
.SYNOPSIS
    Detects whether a PR is on GitHub or Azure DevOps.
.PARAMETER PrInput
    A PR URL or PR number. If a number, inspects git remote to detect platform.
.OUTPUTS
    JSON object: { platform, org, repo, project, prNumber }
    - platform: "github" or "azuredevops"
    - project: populated only for Azure DevOps
#>
param(
    [Parameter(Mandatory)]
    [string]$PrInput
)

$ErrorActionPreference = 'Stop'

$result = @{
    platform = $null
    org      = $null
    repo     = $null
    project  = $null
    prNumber = $null
}

if ($PrInput -match '^https?://') {
    # GitHub: https://github.com/{owner}/{repo}/pull/{number}
    if ($PrInput -match 'github\.com/([^/]+)/([^/]+)/pull/(\d+)') {
        $result.platform = 'github'
        $result.org      = $Matches[1]
        $result.repo     = $Matches[2]
        $result.prNumber = [int]$Matches[3]
    }
    # Azure DevOps: https://dev.azure.com/{org}/{project}/_git/{repo}/pullrequest/{number}
    elseif ($PrInput -match 'dev\.azure\.com/([^/]+)/([^/]+)/_git/([^/]+)/pullrequest/(\d+)') {
        $result.platform = 'azuredevops'
        $result.org      = $Matches[1]
        $result.project  = $Matches[2]
        $result.repo     = $Matches[3]
        $result.prNumber = [int]$Matches[4]
    }
    # Azure DevOps (legacy): https://{org}.visualstudio.com/{project}/_git/{repo}/pullrequest/{number}
    elseif ($PrInput -match '([^/]+)\.visualstudio\.com/([^/]+)/_git/([^/]+)/pullrequest/(\d+)') {
        $result.platform = 'azuredevops'
        $result.org      = $Matches[1]
        $result.project  = $Matches[2]
        $result.repo     = $Matches[3]
        $result.prNumber = [int]$Matches[4]
    }
    else {
        Write-Error "Unrecognized PR URL format: $PrInput"
        exit 1
    }
}
elseif ($PrInput -match '^\d+$') {
    $result.prNumber = [int]$PrInput

    $remotes = git remote -v 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Not in a git repository or git remote failed"
        exit 1
    }

    $match = $remotes | Select-String 'origin.*\(fetch\)' | Select-Object -First 1
    if (-not $match) {
        Write-Error "No 'origin' fetch remote found. Ensure a remote named 'origin' is configured."
        exit 1
    }
    $fetchLine = $match.ToString()

    if ($fetchLine -match 'github\.com[:/]([^/]+)/([^/.\s]+)') {
        $result.platform = 'github'
        $result.org      = $Matches[1]
        $result.repo     = $Matches[2] -replace '\.git$', ''
    }
    elseif ($fetchLine -match 'dev\.azure\.com/([^/]+)/([^/]+)/_git/([^/\s]+)') {
        $result.platform = 'azuredevops'
        $result.org      = $Matches[1]
        $result.project  = $Matches[2]
        $result.repo     = $Matches[3] -replace '\.git$', ''
    }
    elseif ($fetchLine -match '([^/]+)\.visualstudio\.com/([^/]+)/_git/([^/\s]+)') {
        $result.platform = 'azuredevops'
        $result.org      = $Matches[1]
        $result.project  = $Matches[2]
        $result.repo     = $Matches[3] -replace '\.git$', ''
    }
    elseif ($fetchLine -match 'ssh\.dev\.azure\.com.*?/v3/([^/]+)/([^/]+)/([^/\s]+)') {
        $result.platform = 'azuredevops'
        $result.org      = $Matches[1]
        $result.project  = $Matches[2]
        $result.repo     = $Matches[3] -replace '\.git$', ''
    }
    else {
        Write-Error "Could not determine platform from git remote: $fetchLine"
        exit 1
    }
}
else {
    Write-Error "PrInput must be a PR URL or PR number, got: $PrInput"
    exit 1
}

$result | ConvertTo-Json -Compress
