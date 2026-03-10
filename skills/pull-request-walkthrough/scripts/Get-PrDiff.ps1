<#
.SYNOPSIS
    Extracts the diff for a pull request and parses it into structured data.
    For GitHub PRs, uses gh pr diff for accurate server-side diff computation.
    For Azure DevOps PRs, uses az devops invoke to get server-side diff data.
    Falls back to local git diff when platform info is not provided.
.PARAMETER BaseRef
    The base ref (branch name or commit SHA). Used for Azure DevOps API diff and local git fallback.
.PARAMETER HeadRef
    The head ref (branch name or commit SHA). Used for Azure DevOps API diff, local git fallback, and output.
.PARAMETER Platform
    Optional. "github" or "azuredevops". Enables platform-native diff APIs for accuracy.
.PARAMETER Org
    Optional. Organization or owner name (required when Platform is specified).
.PARAMETER Repo
    Optional. Repository name (required when Platform is specified).
.PARAMETER PrNumber
    Optional. Pull request number (required when Platform is "github").
.PARAMETER Project
    Optional. Azure DevOps project name (required when Platform is "azuredevops").
.OUTPUTS
    JSON object containing:
    - baseRef: resolved merge-base commit (or "server" when using platform API)
    - headRef: head commit
    - totalFiles: number of files changed
    - totalAdded: total lines added
    - totalRemoved: total lines removed
    - files[]: array of changed file objects, each with:
      - file: file path
      - changeType: added, deleted, modified, renamed, copied
      - originalFile: original path if renamed (null otherwise)
      - linesAdded: lines added in this file
      - linesRemoved: lines removed in this file
      - hunks[]: array of changed regions with startLine, endLine, context
#>
param(
    [Parameter(Mandatory)][string]$BaseRef,
    [Parameter(Mandatory)][string]$HeadRef,
    [string]$Platform,
    [string]$Org,
    [string]$Repo,
    [int]$PrNumber,
    [string]$Project
)

$ErrorActionPreference = 'Stop'

# Determine which diff strategy to use
$useGhPrDiff = ($Platform -eq 'github' -and $Org -and $Repo -and $PrNumber)
$useAzDoDiff = ($Platform -eq 'azuredevops' -and $Org -and $Repo -and $Project)

function Get-RawDiff {
    if ($useGhPrDiff) {
        # GitHub: gh pr diff returns the exact server-side unified diff
        $raw = gh pr diff $PrNumber --repo "$Org/$Repo" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "gh pr diff failed: $raw"
            exit 1
        }
        return $raw
    }
    elseif ($useAzDoDiff) {
        # Azure DevOps: get the server-side diff via REST API
        $orgUrl = "https://dev.azure.com/$Org"

        # Get the repository ID for the API call
        $repoInfo = az repos show --repository $Repo --org $orgUrl --project $Project --output json 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to get repo info from Azure DevOps, falling back to local git diff: $repoInfo"
            return Get-LocalGitDiff
        }
        $repoId = ($repoInfo | ConvertFrom-Json).id

        # Use the commitDiffs API with diffCommonCommit=true for accurate three-way diff
        $diffResult = az devops invoke `
            --area git --resource commitDiffs `
            --route-parameters project="$Project" repositoryId="$repoId" `
            --query-parameters baseVersion=$BaseRef baseVersionType=commit targetVersion=$HeadRef targetVersionType=commit diffCommonCommit=true `
            --http-method GET --org $orgUrl --api-version 7.1 --output json 2>&1

        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Azure DevOps diffs API failed, falling back to local git diff: $diffResult"
            return Get-LocalGitDiff
        }

        # The diffs API returns structured data, not unified diff.
        # Parse the changed files and generate unified diff per file using local git.
        $diffData = $diffResult | ConvertFrom-Json
        $script:resolvedBase = if ($diffData.commonCommit) { $diffData.commonCommit } else { $BaseRef }

        $rawLines = @()
        foreach ($change in $diffData.changes) {
            $item = $change.item
            if (-not $item -or -not $item.path -or $item.isFolder) { continue }

            # Strip leading / from Azure DevOps paths
            $filePath = $item.path.TrimStart('/')

            # Get unified diff for this specific file using the server-computed common commit
            $fileDiff = git diff --no-color "$($script:resolvedBase)..$HeadRef" -- $filePath 2>&1
            if ($LASTEXITCODE -eq 0 -and $fileDiff) {
                $rawLines += $fileDiff
            }
        }
        return $rawLines
    }
    else {
        return Get-LocalGitDiff
    }
}

function Get-LocalGitDiff {
    # Fallback: compute merge-base locally and diff
    $mergeBase = git merge-base $BaseRef $HeadRef 2>&1
    if ($LASTEXITCODE -ne 0) { $mergeBase = $BaseRef }
    $script:resolvedBase = $mergeBase.Trim()

    $raw = git diff --no-color "$script:resolvedBase..$HeadRef" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "git diff failed: $raw"
        exit 1
    }
    return $raw
}

# Initialize resolvedBase: 'server' for GitHub (no local merge-base needed),
# null otherwise (set later by Azure DevOps API or local git fallback)
$script:resolvedBase = if ($useGhPrDiff) { 'server' } elseif ($useAzDoDiff) { $null } else { $null }

# Get the full raw diff once
$rawDiffLines = Get-RawDiff

# Parse the unified diff output into structured file data
$files = @()
$currentFile = $null
$currentOriginal = $null
$currentChangeType = $null
$currentHunks = @()
$currentAdded = 0
$currentRemoved = 0

function Flush-CurrentFile {
    if ($script:currentFile) {
        $script:files += @{
            file         = $script:currentFile
            changeType   = $script:currentChangeType
            originalFile = $script:currentOriginal
            linesAdded   = $script:currentAdded
            linesRemoved = $script:currentRemoved
            hunks        = $script:currentHunks
        }
    }
}

foreach ($line in $rawDiffLines) {
    # New file header
    if ($line -match '^diff --git a/(.*) b/(.*)') {
        Flush-CurrentFile
        $pathA = $Matches[1]
        $pathB = $Matches[2]
        $currentFile = $pathB
        $currentOriginal = if ($pathA -ne $pathB) { $pathA } else { $null }
        $currentChangeType = 'modified'
        $currentHunks = @()
        $currentAdded = 0
        $currentRemoved = 0
        continue
    }

    # Detect change type from diff header lines
    if ($line -match '^new file mode') {
        $currentChangeType = 'added'
        continue
    }
    if ($line -match '^deleted file mode') {
        $currentChangeType = 'deleted'
        continue
    }
    if ($line -match '^rename from (.*)') {
        $currentChangeType = 'renamed'
        $currentOriginal = $Matches[1]
        continue
    }
    if ($line -match '^copy from (.*)') {
        $currentChangeType = 'copied'
        $currentOriginal = $Matches[1]
        continue
    }

    # Hunk header
    if ($line -match '^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@(.*)') {
        $startLine = [int]$Matches[1]
        $count = if ($Matches[2]) { [int]$Matches[2] } else { 1 }
        $endLine = if ($count -gt 0) { $startLine + $count - 1 } else { $startLine }
        $currentHunks += @{
            startLine = $startLine
            endLine   = $endLine
            context   = $Matches[3].Trim()
        }
        continue
    }

    # Count added/removed lines (lines starting with + or - but not header lines)
    if ($line -match '^\+[^+]' -or $line -eq '+') {
        $currentAdded++
    }
    elseif ($line -match '^-[^-]' -or $line -eq '-') {
        $currentRemoved++
    }
}

# Flush the last file
Flush-CurrentFile

$output = @{
    baseRef      = if ($script:resolvedBase) { $script:resolvedBase } else { $BaseRef }
    headRef      = $HeadRef
    totalFiles   = $files.Count
    totalAdded   = ($files | Measure-Object -Property linesAdded -Sum).Sum
    totalRemoved = ($files | Measure-Object -Property linesRemoved -Sum).Sum
    files        = $files
}

$output | ConvertTo-Json -Depth 10
