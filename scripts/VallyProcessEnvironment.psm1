Set-StrictMode -Version Latest

function Get-VallyProcessPath {
    [CmdletBinding()]
    param(
        [string] $CurrentPath = $env:PATH,
        [ValidateRange(1, 8000)] [int] $MaximumLength = 7000
    )

    $requiredDirectories = foreach ($commandName in @(
        'node', 'git', 'pwsh', 'powershell', 'gh', 'copilot',
        'python', 'python3', 'py', 'dotnet', 'bash'
    )) {
        $command = Get-Command $commandName -CommandType Application -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($command) {
            Split-Path -Parent $command.Source
        }
    }
    if ($env:SystemRoot) {
        $requiredDirectories += @(
            (Join-Path $env:SystemRoot 'System32'),
            (Join-Path $env:SystemRoot 'System32\Wbem'),
            (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0')
        )
    }

    $selected = [Collections.Generic.List[string]]::new()
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($entry in @($requiredDirectories) + @($CurrentPath -split ';')) {
        $directory = $entry.Trim().Trim('"')
        if (-not $directory -or -not $seen.Add($directory)) {
            continue
        }
        $nextLength = $directory.Length
        if ($selected.Count -gt 0) {
            $nextLength++
        }
        if (($selected -join ';').Length + $nextLength -gt $MaximumLength) {
            continue
        }
        $selected.Add($directory)
    }

    $selected -join ';'
}

Export-ModuleMember -Function Get-VallyProcessPath
