[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Title,

    [Parameter(Mandatory = $false)]
    [string]$DecisionsPath = 'docs/decisions',

    [Parameter(Mandatory = $false)]
    [ValidateSet('Proposed', 'Accepted', 'Deprecated', 'Superseded', 'Rejected')]
    [string]$Status = 'Proposed'
)

# Get the skill directory (parent directory of scripts/)
$skillDir = Split-Path -Parent $PSScriptRoot

# Get template path (always use MADR)
$templateFile = Join-Path $skillDir "assets\template-madr.md"

if (-not (Test-Path $templateFile)) {
    Write-Error "Template file not found: $templateFile"
    exit 1
}

# Create decisions directory if it doesn't exist
if (-not (Test-Path $DecisionsPath)) {
    New-Item -ItemType Directory -Path $DecisionsPath -Force | Out-Null
    Write-Host "Created decisions directory: $DecisionsPath"
}

# Find existing ADRs and determine next number
$existingADRs = Get-ChildItem -Path $DecisionsPath -Filter "*.md" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^(\d{4})-' } |
    ForEach-Object {
        [PSCustomObject]@{
            Number = [int]$matches[1]
            Name = $_.Name
        }
    } |
    Sort-Object -Property Number

if ($existingADRs) {
    $nextNumber = ($existingADRs | Select-Object -Last 1).Number + 1
} else {
    $nextNumber = 1
}

# Format number with leading zeros
$numberFormatted = $nextNumber.ToString('0000')

# Create filename from title (lowercase, hyphens, no special chars)
$filenameSafe = $Title -replace '[^\w\s-]', '' -replace '\s+', '-' | ForEach-Object { $_.ToLower() }
$filename = "$numberFormatted-$filenameSafe.md"
$filepath = Join-Path $DecisionsPath $filename

# Check if file already exists
if (Test-Path $filepath) {
    Write-Error "File already exists: $filepath"
    exit 1
}

# Read template content
$templateContent = Get-Content -Path $templateFile -Raw -Encoding UTF8

# Get current date
$currentDate = Get-Date -Format 'yyyy-MM-dd'

# Replace placeholders
$content = $templateContent `
    -replace '\{NUMBER\}', $numberFormatted `
    -replace '\{TITLE\}', $Title `
    -replace '\{DATE\}', $currentDate `
    -replace '\{STATUS\}', $Status

# Write the ADR file
$content | Out-File -FilePath $filepath -Encoding UTF8 -NoNewline

Write-Host "Created ADR: $filepath"
Write-Host "  Number: $numberFormatted"
Write-Host "  Title: $Title"
Write-Host "  Status: $Status"

# Return the filepath for Claude to use
Write-Output $filepath
