Set-StrictMode -Version Latest

BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

Describe "Build-VallyDashboardManifest.ps1" {
    It "keeps mixed legacy skill history and excludes uplift history" {
        $pages = Join-Path $TestDrive "mixed-pages"
        $historyDir = Join-Path $pages "data\code-review"
        $upliftDir = Join-Path $pages "data\uplift"
        New-Item -ItemType Directory -Path $historyDir, $upliftDir -Force | Out-Null
        @(
            '{"schema_version":1,"run_id":"old","skill":"code-review","commit":"aaa","short_sha":"aaa","timestamp":"2026-01-01T00:00:00Z","status":"ok","headline_score":80,"metrics":{"tp":4,"fn":1}}'
            '{"schema_version":2,"run_id":"new","run_kind":"nightly","skill":"code-review","commit":"bbb","short_sha":"bbb","timestamp":"2026-01-02T00:00:00Z","status":"ok","metrics":{"pass_rate":0.5,"mean_score":0.6}}'
        ) | Set-Content (Join-Path $historyDir "history.jsonl")
        '{"schema_version":1,"run_id":"new","timestamp":"2026-01-02T00:00:00Z","commit":"bbb","overall":{"mean_score":0.2},"skills":[],"comparison_file":"data/uplift/runs/new.jsonl"}' |
            Set-Content (Join-Path $upliftDir "history.jsonl")

        & (Join-Path $repoRoot "scripts\Build-VallyDashboardManifest.ps1") `
            -PagesDir $pages -Repository "owner/repo"

        $manifest = Get-Content (Join-Path $pages "data\manifest.json") -Raw | ConvertFrom-Json
        @($manifest.skills).Count | Should -Be 1
        $manifest.skills[0].name | Should -Be "code-review"
        $manifest.skills[0].run_count | Should -Be 2
        $manifest.skills[0].sparkline[0].run_kind | Should -Be "legacy"
        $manifest.skills[0].sparkline[0].pass_rate | Should -BeNullOrEmpty
        $manifest.skills[0].latest.metrics.pass_rate | Should -Be 0.5
        $manifest.skills[0].latest.delta_from_previous | Should -BeNullOrEmpty
        $manifest.uplift_history | Should -Be "data/uplift/history.jsonl"
    }

    It "builds schema-v2 summaries and the worst recent regression" {
        $pages = Join-Path $TestDrive "pages"
        $historyDir = Join-Path $pages "data\code-review"
        New-Item -ItemType Directory -Path $historyDir -Force | Out-Null
        @(
            '{"schema_version":2,"run_id":"1","run_kind":"nightly","skill":"code-review","commit":"aaa","short_sha":"aaa","timestamp":"2026-01-01T00:00:00Z","status":"ok","metrics":{"pass_rate":0.9,"mean_score":0.8}}'
            '{"schema_version":2,"run_id":"2","run_kind":"nightly","skill":"code-review","commit":"bbb","short_sha":"bbb","timestamp":"2026-01-02T00:00:00Z","status":"ok","metrics":{"pass_rate":0.5,"mean_score":0.6}}'
        ) | Set-Content (Join-Path $historyDir "history.jsonl")

        & (Join-Path $repoRoot "scripts\Build-VallyDashboardManifest.ps1") `
            -PagesDir $pages `
            -Repository "owner/repo"

        $manifest = Get-Content (Join-Path $pages "data\manifest.json") -Raw | ConvertFrom-Json
        $manifest.schema_version | Should -Be 2
        $manifest.repository | Should -Be "owner/repo"
        $manifest.skills[0].latest.metrics.pass_rate | Should -Be 0.5
        $manifest.skills[0].biggest_drop_last_10.delta | Should -Be (-0.4)
        $manifest.worst_recent_drop.skill | Should -Be "code-review"
    }
}

Describe "VallyProcessEnvironment.psm1" {
    It "keeps required tools resolvable for Windows shell children with a long PATH" {
        Import-Module (Join-Path $repoRoot "scripts\VallyProcessEnvironment.psm1") -Force
        $originalPath = $env:PATH
        $compactPath = Get-VallyProcessPath -CurrentPath ("C:\extra\path;" * 1200)
        try {
            $env:PATH = $compactPath
            $node = (Get-Command node -ErrorAction Stop).Source
            $output = & $node -e "require('node:child_process').exec('git --version', (error, stdout) => { if (error) process.exitCode = 1; else process.stdout.write(stdout) })"

            $compactPath.Length | Should -BeLessThan 8000
            $output | Should -Match '^git version '
        }
        finally {
            $env:PATH = $originalPath
        }
    }
}

Describe "Invoke-VallyRegression.ps1" {
    It "succeeds when no stored trajectories exist" {
        {
            & (Join-Path $repoRoot "scripts\Invoke-VallyRegression.ps1")
        } | Should -Not -Throw
    }
}

Describe "Start-EvalDashboard.ps1" {
    It "selects the newest local run with results without querying GitHub" {
        $oldLocalAppData = $env:LOCALAPPDATA
        $root = Join-Path $TestDrive "local-repo"
        $older = Join-Path $root "vally-results\nightly-20260101-old"
        $newer = Join-Path $root "vally-results\nightly-20260102-new"
        $empty = Join-Path $root "vally-results\nightly-20260103-empty"
        New-Item -ItemType Directory -Path $older, $newer, $empty -Force | Out-Null
        '{}' | Set-Content (Join-Path $older 'results.jsonl')
        '{}' | Set-Content (Join-Path $newer 'results.jsonl')
        Mock git { $root }
        Mock Get-Command { [pscustomobject]@{ Source = 'node' } } -ParameterFilter { $Name -eq 'node' }
        Mock Test-Path { $true } -ParameterFilter { $Path -like '*vally-cli*' }
        Mock node {
            $global:LASTEXITCODE = 0
            if ($args[0] -eq '--version') { 'v25.0.0' }
        }
        Mock Start-Process { [pscustomobject]@{ Id = 987654; HasExited = $false } }
        Mock Invoke-WebRequest { [pscustomobject]@{ StatusCode = 200 } }
        Mock gh { throw 'Local results must not query GitHub.' }
        try {
            $env:LOCALAPPDATA = Join-Path $TestDrive 'latest-cache'
            & (Join-Path $repoRoot 'scripts\Start-EvalDashboard.ps1') -Latest -NoOpen
            Should -Invoke node -Times 1 -ParameterFilter {
                $args[1] -eq 'ingest' -and $args[2] -eq $newer
            }
            Should -Invoke gh -Times 0
        }
        finally {
            $env:LOCALAPPDATA = $oldLocalAppData
        }
    }

    It "reports missing local results without querying GitHub" {
        $oldLocalAppData = $env:LOCALAPPDATA
        Mock git { Join-Path $TestDrive 'missing-repo' }
        Mock Test-Path { $true } -ParameterFilter { $Path -like '*vally-cli*' }
        Mock gh { throw 'Local results must not query GitHub.' }
        try {
            $env:LOCALAPPDATA = Join-Path $TestDrive 'missing-cache'
            { & (Join-Path $repoRoot 'scripts\Start-EvalDashboard.ps1') -Latest -NoOpen } |
                Should -Throw '*No local evaluation results were found*'
            Should -Invoke gh -Times 0
        }
        finally {
            $env:LOCALAPPDATA = $oldLocalAppData
        }
    }

    It "ingests nested run directories before serving its database" {
        $oldLocalAppData = $env:LOCALAPPDATA
        $results = Join-Path $TestDrive "nested results"
        $runDir = Join-Path $results "tdd\2026-10-07T12-00-00-000Z"
        New-Item -ItemType Directory -Path $runDir -Force | Out-Null
        [IO.File]::WriteAllText(
            (Join-Path $runDir "results.jsonl"),
            '{"type":"trial-result","itemId":"tdd::fixture","evalName":"tdd","stimulus":"fixture","model":"test-model","status":"success","durationMs":10,"gradeResult":null,"trajectory":null}'
        )
        Mock Start-Process {
            [pscustomobject]@{ Id = 987654; HasExited = $false }
        }
        Mock Invoke-WebRequest { [pscustomobject]@{ StatusCode = 200 } }
        try {
            $env:LOCALAPPDATA = Join-Path $TestDrive "launcher cache"
            & (Join-Path $repoRoot "scripts\Start-EvalDashboard.ps1") `
                -ResultsDir $results -NoOpen
            $store = Join-Path $env:LOCALAPPDATA "superpowers\eval-dashboard\local\eval-history.db"
            Test-Path $store | Should -BeTrue
            $server = (Join-Path $repoRoot "evals\_vally\node_modules\@microsoft\vally-server\dist\index.js").Replace('\', '/')
            $storeUrl = $store.Replace('\', '/')
            $serverJson = ConvertTo-Json -InputObject $server -Compress
            $storeJson = ConvertTo-Json -InputObject $storeUrl -Compress
            $query = "import { pathToFileURL } from 'node:url'; const { initializeDatabase } = await import(pathToFileURL($serverJson).href); const db = initializeDatabase($storeJson); console.log(JSON.stringify(db.prepare('SELECT (SELECT COUNT(*) FROM runs) AS runs, (SELECT COUNT(*) FROM outcomes) AS outcomes').get())); db.close();"
            $count = & node --input-type=module -e $query
            $LASTEXITCODE | Should -Be 0
            $count | Should -Be '{"runs":1,"outcomes":1}'
            Should -Invoke Start-Process -Times 1 -ParameterFilter {
                $ArgumentList -contains 'serve' -and $ArgumentList -contains '--store'
            }
        }
        finally {
            $env:LOCALAPPDATA = $oldLocalAppData
        }
    }

    It "can stop cleanly when no local server state exists" {
        $oldLocalAppData = $env:LOCALAPPDATA
        try {
            $env:LOCALAPPDATA = Join-Path $TestDrive "local-app-data"
            $output = & (Join-Path $repoRoot "scripts\Start-EvalDashboard.ps1") -Stop 2>&1
            Test-Path (Join-Path $env:LOCALAPPDATA "superpowers\eval-dashboard\server.json") |
                Should -BeFalse
        } finally {
            $env:LOCALAPPDATA = $oldLocalAppData
        }
    }

    Describe "Invoke-VallyNightly.ps1" {
        It "does not have an evaluation Actions workflow" {
            Test-Path (Join-Path $repoRoot '.github\workflows\skill-eval.yml') |
                Should -BeFalse
        }

        It "selects the nightly tag when running eval specs individually" {
            $script = Get-Content (Join-Path $repoRoot "scripts\Invoke-VallyNightly.ps1") -Raw
            $script | Should -Match '--eval-spec \$evalSpec\.FullName'
            $script | Should -Match '--tag loop=nightly'
            $script | Should -Not -Match '--suite nightly'
        }

        It "resolves every eval and the uplift experiment without running models" {
            {
                & (Join-Path $repoRoot "scripts\Invoke-VallyNightly.ps1") -DryRun
            } | Should -Not -Throw
        }

        It "publishes through a pull request targeting gh-pages" {
            $script = Get-Content (Join-Path $repoRoot "scripts\Invoke-VallyNightly.ps1") -Raw
            $script | Should -Match 'gh pr create'
            $script | Should -Match '--base gh-pages'
            $script | Should -Match '--head \$publicationBranch'
            $script | Should -Match 'require a clean source worktree'
            $script | Should -Match "yyyyMMdd-HHmmssfff"
            ([regex]::Matches($script, '--param "RUNS=\$Runs"')).Count | Should -Be 2
            $script | Should -Not -Match 'push origin HEAD:gh-pages'
        }
    }
}
