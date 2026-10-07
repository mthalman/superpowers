<#
.SYNOPSIS
    Pester tests for scripts/sync-dashboard.ps1.

    Run:
        Invoke-Pester -Path tests/skill-eval/Dashboard.Tests.ps1 -Output Detailed
#>

BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:SyncPs1  = Join-Path $RepoRoot 'scripts' 'sync-dashboard.ps1'

    function script:Seed-DashboardSource {
        param([string] $Root)
        New-Item -ItemType Directory -Path (Join-Path $Root 'assets') -Force | Out-Null
        Set-Content (Join-Path $Root 'index.html')        '<html>index v1</html>'
        Set-Content (Join-Path $Root 'skill.html')        '<html>skill v1</html>'
        Set-Content (Join-Path $Root 'nightly.html')      '<html>nightly v1</html>'
        Set-Content (Join-Path $Root 'README.md')         '# dashboard dev notes'
        Set-Content (Join-Path $Root 'assets/app.js')     'console.log("v1");'
        Set-Content (Join-Path $Root 'assets/styles.css') 'body {}'
    }
}

Describe 'sync-dashboard.ps1' {

    BeforeEach {
        $caseRoot = Join-Path $TestDrive ([Guid]::NewGuid().ToString('N'))
        $script:Src = Join-Path $caseRoot 'source'
        $script:Pages = Join-Path $caseRoot 'pages'
        New-Item -ItemType Directory -Path $Src, $Pages -Force | Out-Null
        Seed-DashboardSource -Root $Src
    }

    It 'copies dashboard HTML and assets to the pages root' {
        & $SyncPs1 -SourceDir $Src -PagesDir $Pages | Out-Null
        Test-Path (Join-Path $Pages 'index.html')          | Should -BeTrue
        Test-Path (Join-Path $Pages 'skill.html')          | Should -BeTrue
        Test-Path (Join-Path $Pages 'nightly.html')        | Should -BeTrue
        Test-Path (Join-Path $Pages 'assets/app.js')       | Should -BeTrue
        Test-Path (Join-Path $Pages 'assets/styles.css')   | Should -BeTrue
    }

    It 'never copies dashboard/README.md to the pages root' {
        Set-Content (Join-Path $Pages 'README.md') '# gh-pages README (must be preserved)'
        & $SyncPs1 -SourceDir $Src -PagesDir $Pages | Out-Null
        (Get-Content (Join-Path $Pages 'README.md') -Raw).Trim() | Should -Be '# gh-pages README (must be preserved)'
    }

    It 'preserves .nojekyll, data/, and existing README.md' {
        Set-Content (Join-Path $Pages '.nojekyll') ''
        Set-Content (Join-Path $Pages 'README.md') '# preserved'
        New-Item -ItemType Directory -Path (Join-Path $Pages 'data/code-review/runs') -Force | Out-Null
        Set-Content (Join-Path $Pages 'data/manifest.json') '{"skills":[]}'
        Set-Content (Join-Path $Pages 'data/code-review/history.jsonl') '{"commit":"a"}'

        & $SyncPs1 -SourceDir $Src -PagesDir $Pages | Out-Null

        Test-Path (Join-Path $Pages '.nojekyll')                       | Should -BeTrue
        (Get-Content (Join-Path $Pages 'README.md') -Raw).Trim()       | Should -Be '# preserved'
        Test-Path (Join-Path $Pages 'data/manifest.json')              | Should -BeTrue
        Test-Path (Join-Path $Pages 'data/code-review/history.jsonl')  | Should -BeTrue
    }

    It 'overwrites stale dashboard files with newer source content' {
        New-Item -ItemType Directory -Path (Join-Path $Pages 'assets') -Force | Out-Null
        Set-Content (Join-Path $Pages 'index.html')      '<html>OLD</html>'
        Set-Content (Join-Path $Pages 'assets/app.js')   'console.log("OLD");'

        & $SyncPs1 -SourceDir $Src -PagesDir $Pages | Out-Null

        (Get-Content (Join-Path $Pages 'index.html') -Raw).Trim()    | Should -Be '<html>index v1</html>'
        (Get-Content (Join-Path $Pages 'assets/app.js') -Raw).Trim() | Should -Be 'console.log("v1");'
    }

    It 'removes stale files inside assets/ that no longer exist in source' {
        New-Item -ItemType Directory -Path (Join-Path $Pages 'assets') -Force | Out-Null
        Set-Content (Join-Path $Pages 'assets/dead.js') 'orphan'

        & $SyncPs1 -SourceDir $Src -PagesDir $Pages | Out-Null

        Test-Path (Join-Path $Pages 'assets/dead.js') | Should -BeFalse
        Test-Path (Join-Path $Pages 'assets/app.js')  | Should -BeTrue
    }

    It 'does not remove non-dashboard files at the pages root even if dashboard sources changed' {
        Set-Content (Join-Path $Pages 'custom-page.html') 'user-owned'

        & $SyncPs1 -SourceDir $Src -PagesDir $Pages | Out-Null

        Test-Path (Join-Path $Pages 'custom-page.html') | Should -BeTrue
    }

    It 'creates assets/ on the pages side when missing' {
        Remove-Item -Recurse -Force (Join-Path $Pages 'assets') -ErrorAction SilentlyContinue
        & $SyncPs1 -SourceDir $Src -PagesDir $Pages | Out-Null
        Test-Path (Join-Path $Pages 'assets/app.js') | Should -BeTrue
    }

    It 'mirrors nested assets/ structure (subdirectories)' {
        New-Item -ItemType Directory -Path (Join-Path $Src 'assets/icons') -Force | Out-Null
        Set-Content (Join-Path $Src 'assets/icons/error.svg') '<svg/>'

        & $SyncPs1 -SourceDir $Src -PagesDir $Pages | Out-Null

        Test-Path (Join-Path $Pages 'assets/icons/error.svg') | Should -BeTrue
    }

    It 'prunes now-empty subdirectories inside assets/' {
        New-Item -ItemType Directory -Path (Join-Path $Pages 'assets/dead-dir') -Force | Out-Null
        Set-Content (Join-Path $Pages 'assets/dead-dir/orphan.txt') 'x'

        & $SyncPs1 -SourceDir $Src -PagesDir $Pages | Out-Null

        Test-Path (Join-Path $Pages 'assets/dead-dir/orphan.txt') | Should -BeFalse
        Test-Path (Join-Path $Pages 'assets/dead-dir')            | Should -BeFalse
    }
}
