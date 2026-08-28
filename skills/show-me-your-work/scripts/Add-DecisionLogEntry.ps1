[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $Path,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Phase,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Decision,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Why,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Evidence,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Result,

    [datetimeoffset] $Timestamp = [datetimeoffset]::UtcNow
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ExpectedHeader = "ts`tphase`tdecision`twhy`tevidence`tresult"
$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$Utf8Strict = [System.Text.UTF8Encoding]::new($false, $true)

function ConvertTo-DecisionLogCell {
    param([Parameter(Mandatory)][string] $Value)

    $normalized = ($Value -replace '[\t\r\n]+', ' ').Trim()
    if (-not $normalized) {
        throw 'Decision log cells cannot be empty after normalization.'
    }

    # Spreadsheet applications can execute generated cells as formulas.
    if ($normalized[0] -in '=', '+', '-', '@') {
        return "'" + $normalized
    }

    return $normalized
}

$fullPath = [System.IO.Path]::GetFullPath($Path)
$parent = [System.IO.Path]::GetDirectoryName($fullPath)
if ($parent -and -not [System.IO.Directory]::Exists($parent)) {
    [void][System.IO.Directory]::CreateDirectory($parent)
}

$cells = @(
    $Timestamp.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    ConvertTo-DecisionLogCell -Value $Phase
    ConvertTo-DecisionLogCell -Value $Decision
    ConvertTo-DecisionLogCell -Value $Why
    ConvertTo-DecisionLogCell -Value $Evidence
    ConvertTo-DecisionLogCell -Value $Result
)
$row = $cells -join "`t"

$deadline = [datetime]::UtcNow.AddSeconds(5)
$delayMilliseconds = 25
$stream = $null
do {
    try {
        $stream = [System.IO.File]::Open(
            $fullPath,
            [System.IO.FileMode]::OpenOrCreate,
            [System.IO.FileAccess]::ReadWrite,
            [System.IO.FileShare]::Read
        )
    }
    catch [System.IO.IOException] {
        if ([datetime]::UtcNow -ge $deadline) {
            throw
        }
        Start-Sleep -Milliseconds $delayMilliseconds
        $delayMilliseconds = [math]::Min($delayMilliseconds * 2, 250)
    }
} while ($null -eq $stream)

try {
    $reader = [System.IO.StreamReader]::new($stream, $Utf8Strict, $false, 1024, $true)
    try {
        try {
            $existing = $reader.ReadToEnd()
        }
        catch [System.Text.DecoderFallbackException] {
            throw "Existing decision log '$fullPath' is not valid UTF-8."
        }
    }
    finally {
        $reader.Dispose()
    }

    if ($existing.StartsWith([char]0xFEFF)) {
        $existing = $existing.Substring(1)
    }

    if ($existing) {
        $firstLine = ($existing -split '\r?\n', 2)[0]
        if ($firstLine -ne $ExpectedHeader) {
            throw "Existing decision log '$fullPath' has an unexpected header."
        }
    }

    [void]$stream.Seek(0, [System.IO.SeekOrigin]::End)
    $writer = [System.IO.StreamWriter]::new($stream, $Utf8NoBom, 1024, $true)
    try {
        if (-not $existing) {
            $writer.WriteLine($ExpectedHeader)
        }
        elseif (-not ($existing.EndsWith("`n"))) {
            $writer.WriteLine()
        }
        $writer.WriteLine($row)
        $writer.Flush()
    }
    finally {
        $writer.Dispose()
    }
}
finally {
    $stream.Dispose()
}

[pscustomobject]@{
    Path      = $fullPath
    Timestamp = $cells[0]
    Phase     = $cells[1]
    Decision  = $cells[2]
    Why       = $cells[3]
    Evidence  = $cells[4]
    Result    = $cells[5]
}
