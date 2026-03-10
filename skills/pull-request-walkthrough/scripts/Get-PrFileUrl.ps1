<#
.SYNOPSIS
    Generates a navigable URL to a file in a pull request's diff view.
.PARAMETER Platform
    "github" or "azuredevops"
.PARAMETER Org
    Organization or owner name
.PARAMETER Repo
    Repository name
.PARAMETER PrNumber
    Pull request number
.PARAMETER FilePath
    Path to the file within the repository (e.g., "src/Foo.cs")
.PARAMETER LineNumber
    Optional. Line number to anchor to (right side of diff).
.PARAMETER Project
    Optional. Azure DevOps project name (required for azuredevops platform).
.PARAMETER HeadRefOid
    Optional. Head commit SHA. Used for blob-view fallback links.
.OUTPUTS
    The URL string pointing to the file in the PR diff view.
#>
param(
    [Parameter(Mandatory)][string]$Platform,
    [Parameter(Mandatory)][string]$Org,
    [Parameter(Mandatory)][string]$Repo,
    [Parameter(Mandatory)][int]$PrNumber,
    [Parameter(Mandatory)][string]$FilePath,
    [int]$LineNumber,
    [string]$Project,
    [string]$HeadRefOid
)

$ErrorActionPreference = 'Stop'

if ($Platform -eq 'github') {
    # GitHub PR files view anchors files by SHA256 hash of the file path
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($FilePath)
    $hash = [System.Security.Cryptography.SHA256]::HashData($bytes)
    $hex = [System.BitConverter]::ToString($hash).Replace('-', '').ToLower()

    $url = "https://github.com/$Org/$Repo/pull/$PrNumber/files#diff-$hex"

    # Line anchors use R{line} for right-side (new file) lines
    if ($LineNumber -gt 0) {
        $url += "R$LineNumber"
    }

    $url
}
elseif ($Platform -eq 'azuredevops') {
    if (-not $Project) {
        Write-Error "Project parameter is required for Azure DevOps PRs"
        exit 1
    }

    # Azure DevOps PR file view URL
    $encodedPath = [Uri]::EscapeDataString("/$FilePath")
    $url = "https://dev.azure.com/$Org/$Project/_git/$Repo/pullrequest/$PrNumber"
    $url += "?_a=files&path=$encodedPath"

    if ($LineNumber -gt 0) {
        $url += "&line=$LineNumber&lineEnd=$($LineNumber + 1)&lineStartColumn=1&lineEndColumn=1"
    }

    $url
}
else {
    Write-Error "Unknown platform: $Platform. Expected 'github' or 'azuredevops'."
    exit 1
}
