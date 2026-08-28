BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:ScriptPath = Join-Path $RepoRoot 'skills' 'show-me-your-work' 'scripts' 'Add-DecisionLogEntry.ps1'
    $script:TempRoot = Join-Path ([IO.Path]::GetTempPath()) ("decision-log-tests-" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $TempRoot | Out-Null
}

AfterAll {
    Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Add-DecisionLogEntry.ps1' {
    It 'creates the canonical header and appends a normalized row' {
        $path = Join-Path $TempRoot 'nested' 'decisions.tsv'

        & $ScriptPath `
            -Path $path `
            -Phase "design`nreview" `
            -Decision 'selected base' `
            -Why 'smallest public surface' `
            -Evidence 'skills/arena/SKILL.md:90' `
            -Result 'open' `
            -Timestamp ([datetimeoffset]'2026-08-27T12:34:56Z') | Out-Null

        $lines = @(Get-Content -LiteralPath $path)
        $lines.Count | Should -Be 2
        $lines[0] | Should -Be "ts`tphase`tdecision`twhy`tevidence`tresult"
        $lines[1] | Should -Be "2026-08-27T12:34:56.000Z`tdesign review`tselected base`tsmallest public surface`tskills/arena/SKILL.md:90`topen"
    }

    It 'neutralizes spreadsheet formulas in generated cells' {
        $path = Join-Path $TempRoot 'formula.tsv'

        & $ScriptPath `
            -Path $path `
            -Phase '=cmd' `
            -Decision '+SUM(A1:A2)' `
            -Why '-unsafe' `
            -Evidence '@artifact' `
            -Result 'open' | Out-Null

        $row = (Get-Content -LiteralPath $path)[1]
        $row | Should -Match "\t'=cmd\t'\+SUM\(A1:A2\)\t'-unsafe\t'@artifact\topen$"
    }

    It 'preserves repeated spaces inside evidence pointers' {
        $path = Join-Path $TempRoot 'spaces.tsv'

        & $ScriptPath `
            -Path $path `
            -Phase 'evidence' `
            -Decision 'record path' `
            -Why 'path must remain resolvable' `
            -Evidence 'C:\logs\build  output.txt' `
            -Result 'open' | Out-Null

        $row = (Get-Content -LiteralPath $path)[1]
        $row | Should -Match ([regex]::Escape("C:\logs\build  output.txt"))
    }

    It 'appends without duplicating the header' {
        $path = Join-Path $TempRoot 'append.tsv'
        $common = @{
            Path     = $path
            Why      = 'reason'
            Evidence = 'artifact'
            Result   = 'open'
        }

        & $ScriptPath @common -Phase 'one' -Decision 'first' | Out-Null
        & $ScriptPath @common -Phase 'two' -Decision 'second' | Out-Null

        $lines = @(Get-Content -LiteralPath $path)
        $lines.Count | Should -Be 3
        @($lines | Where-Object { $_ -eq "ts`tphase`tdecision`twhy`tevidence`tresult" }).Count |
            Should -Be 1
    }

    It 'retries concurrent writers without losing rows' {
        $path = Join-Path $TempRoot 'concurrent.tsv'
        $jobs = @(1..8 | ForEach-Object {
            Start-Job -ScriptBlock {
                param($ScriptPath, $LogPath, $Id)
                & $ScriptPath `
                    -Path $LogPath `
                    -Phase 'parallel' `
                    -Decision "decision $Id" `
                    -Why 'concurrent test' `
                    -Evidence "artifact-$Id" `
                    -Result 'open' | Out-Null
            } -ArgumentList $ScriptPath, $path, $_
        })

        try {
            $jobs | Wait-Job | Out-Null
            @($jobs | Where-Object { $_.State -ne 'Completed' }).Count | Should -Be 0
            $jobs | Receive-Job
        }
        finally {
            $jobs | Remove-Job -Force -ErrorAction SilentlyContinue
        }

        $lines = @(Get-Content -LiteralPath $path)
        $lines.Count | Should -Be 9
        @($lines | Select-Object -Skip 1 | Sort-Object -Unique).Count | Should -Be 8
    }

    It 'rejects a file with an incompatible header' {
        $path = Join-Path $TempRoot 'invalid.tsv'
        Set-Content -LiteralPath $path -Value "wrong`theader" -Encoding utf8NoBOM

        {
            & $ScriptPath `
                -Path $path `
                -Phase 'phase' `
                -Decision 'decision' `
                -Why 'reason' `
                -Evidence 'artifact' `
                -Result 'open'
        } | Should -Throw '*unexpected header*'
    }

    It 'rejects an existing UTF-16 log instead of creating mixed encoding' {
        $path = Join-Path $TempRoot 'utf16.tsv'
        $header = "ts`tphase`tdecision`twhy`tevidence`tresult`r`n"
        [IO.File]::WriteAllText($path, $header, [Text.UnicodeEncoding]::new($false, $true))

        {
            & $ScriptPath `
                -Path $path `
                -Phase 'phase' `
                -Decision 'decision' `
                -Why 'reason' `
                -Evidence 'artifact' `
                -Result 'open'
        } | Should -Throw '*not valid UTF-8*'
    }
}
