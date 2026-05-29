<#
.SYNOPSIS
    Pester tests for the per-commit skill-eval workflow scripts:
      scripts/detect-changed-skills.ps1
      scripts/wrap-eval-output.ps1
      scripts/build-manifest.ps1
      evals/code-review/run-eval.ps1 (Pattern A aggregation)

    Run:
        Invoke-Pester -Path tests/skill-eval/SkillEval.Tests.ps1 -Output Detailed
#>

BeforeAll {
    $script:RepoRoot   = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:DetectPs1  = Join-Path $RepoRoot 'scripts' 'detect-changed-skills.ps1'
    $script:WrapPs1    = Join-Path $RepoRoot 'scripts' 'wrap-eval-output.ps1'
    $script:BuildPs1   = Join-Path $RepoRoot 'scripts' 'build-manifest.ps1'
    $script:RunEvalPs1 = Join-Path $RepoRoot 'evals' 'code-review' 'run-eval.ps1'
    $script:Utf8NoBom  = New-Object System.Text.UTF8Encoding($false)

    function script:New-TempDir {
        $p = Join-Path ([IO.Path]::GetTempPath()) ("skilleval-tests-" + [Guid]::NewGuid().ToString('N').Substring(0,12))
        New-Item -ItemType Directory -Path $p | Out-Null
        return $p
    }
}

# ============================================================================
# detect-changed-skills.ps1
# ============================================================================

Describe 'detect-changed-skills.ps1' {

    BeforeEach {
        $script:Repo = New-TempDir
        Push-Location $Repo
        & git init -q
        & git config user.email "t@example.com"
        & git config user.name "t"
        New-Item -ItemType Directory -Path "evals" | Out-Null
        New-Item -ItemType Directory -Path "skills" | Out-Null
        Set-Content "README.md" "init"
        & git add .
        & git commit -q -m "init"
    }

    AfterEach {
        Pop-Location
        Remove-Item -Recurse -Force $Repo -ErrorAction SilentlyContinue
    }

    It 'returns [] when no skills exist' {
        $out = & pwsh -NoProfile -File $DetectPs1 -RepoRoot $Repo -BaseRef '--full-sweep'
        $out | Should -Be '[]'
    }

    It 'returns a skill when its run-eval.ps1 exists and matching paths changed' {
        New-Item -ItemType Directory -Path "evals/code-review" | Out-Null
        Set-Content "evals/code-review/run-eval.ps1" "# stub"
        & git add .
        & git commit -q -m "add eval"

        New-Item -ItemType Directory -Path "skills/code-review" | Out-Null
        Set-Content "skills/code-review/SKILL.md" "edit"
        & git add .
        & git commit -q -m "edit skill"

        $out = & pwsh -NoProfile -File $DetectPs1 -RepoRoot $Repo -BaseRef "HEAD~1" -HeadRef HEAD
        $out | Should -Be '["code-review"]'
    }

    It 'returns [] when no relevant paths changed' {
        New-Item -ItemType Directory -Path "evals/code-review" | Out-Null
        Set-Content "evals/code-review/run-eval.ps1" "# stub"
        & git add .
        & git commit -q -m "add eval"

        Set-Content "README.md" "edit unrelated"
        & git add .
        & git commit -q -m "unrelated"

        $out = & pwsh -NoProfile -File $DetectPs1 -RepoRoot $Repo -BaseRef "HEAD~1" -HeadRef HEAD
        $out | Should -Be '[]'
    }

    It 'sweeps every skill with run-eval.ps1 when evals/_shared/ changes' {
        New-Item -ItemType Directory -Path "evals/code-review" | Out-Null
        New-Item -ItemType Directory -Path "evals/other-skill" | Out-Null
        New-Item -ItemType Directory -Path "evals/_shared" | Out-Null
        Set-Content "evals/code-review/run-eval.ps1" "# stub"
        Set-Content "evals/other-skill/run-eval.ps1" "# stub"
        Set-Content "evals/_shared/README.md" "shared"
        & git add .
        & git commit -q -m "add suites + shared"

        Set-Content "evals/_shared/README.md" "shared v2"
        & git add .
        & git commit -q -m "edit shared"

        $out = & pwsh -NoProfile -File $DetectPs1 -RepoRoot $Repo -BaseRef "HEAD~1" -HeadRef HEAD
        $out | Should -Be '["code-review","other-skill"]'
    }

    It 'excludes skills without run-eval.ps1' {
        New-Item -ItemType Directory -Path "evals/code-review" | Out-Null
        New-Item -ItemType Directory -Path "skills/no-eval-skill" | Out-Null
        Set-Content "evals/code-review/run-eval.ps1" "# stub"
        Set-Content "skills/no-eval-skill/SKILL.md" "x"
        & git add .
        & git commit -q -m "add"

        Set-Content "skills/no-eval-skill/SKILL.md" "y"
        & git add .
        & git commit -q -m "edit no-eval"

        $out = & pwsh -NoProfile -File $DetectPs1 -RepoRoot $Repo -BaseRef "HEAD~1" -HeadRef HEAD
        $out | Should -Be '[]'
    }

    It 'full-sweep mode returns every skill regardless of git state' {
        New-Item -ItemType Directory -Path "evals/aaa-skill" | Out-Null
        New-Item -ItemType Directory -Path "evals/bbb-skill" | Out-Null
        Set-Content "evals/aaa-skill/run-eval.ps1" "# stub"
        Set-Content "evals/bbb-skill/run-eval.ps1" "# stub"
        & git add .
        & git commit -q -m "add"

        $out = & pwsh -NoProfile -File $DetectPs1 -RepoRoot $Repo -BaseRef '--full-sweep'
        $out | Should -Be '["aaa-skill","bbb-skill"]'
    }

    It 'OnlySkills allow-list intersects results' {
        New-Item -ItemType Directory -Path "evals/aaa-skill" | Out-Null
        New-Item -ItemType Directory -Path "evals/bbb-skill" | Out-Null
        Set-Content "evals/aaa-skill/run-eval.ps1" "# stub"
        Set-Content "evals/bbb-skill/run-eval.ps1" "# stub"
        & git add .
        & git commit -q -m "add"

        $out = & pwsh -NoProfile -File $DetectPs1 -RepoRoot $Repo -BaseRef '--full-sweep' -OnlySkills "bbb-skill"
        $out | Should -Be '["bbb-skill"]'
    }
}

# ============================================================================
# wrap-eval-output.ps1
# ============================================================================

Describe 'wrap-eval-output.ps1' {

    BeforeEach {
        $script:Pages   = New-TempDir
        $script:EvalOut = New-TempDir
    }

    AfterEach {
        Remove-Item -Recurse -Force $Pages -ErrorAction SilentlyContinue
        Remove-Item -Recurse -Force $EvalOut -ErrorAction SilentlyContinue
    }

    It 'writes a single JSONL row + run-detail file for a good run' {
        $headline = @{
            schema_version = 1; pattern = "A"; headline_score = 87.5
            status = "ok"; adapter = "smoke"; trials = 3
            metrics = @{ tp = 21; fn = 3; case_count = 8; required_bug_count = 24 }
        } | ConvertTo-Json -Compress -Depth 10
        [IO.File]::WriteAllText((Join-Path $EvalOut 'headline-score.json'), $headline, $Utf8NoBom)
        [IO.File]::WriteAllText((Join-Path $EvalOut 'run-detail.json'),
            (@{ schema_version=1; pattern="A"; detail=@{ cases=@() } } | ConvertTo-Json -Compress -Depth 10), $Utf8NoBom)

        & pwsh -NoProfile -File $WrapPs1 -Skill code-review -EvalOutDir $EvalOut -PagesDir $Pages -Commit "abc1234567" -CommitMessage "msg" -CommitAuthor "a" -Timestamp "2026-05-29T00:00:00Z" | Out-Null

        $hist = Join-Path $Pages 'data/code-review/history.jsonl'
        $hist | Should -Exist
        $lines = @(Get-Content $hist | Where-Object { $_ })
        $lines.Count | Should -Be 1
        $row = $lines[0] | ConvertFrom-Json
        $row.headline_score | Should -Be 87.5
        $row.status | Should -Be 'ok'
        $row.short_sha | Should -Be 'abc1234'
        $row.metrics.tp | Should -Be 21
        $row.detail_file | Should -Be 'runs/2026-05-29T00-00-00Z-abc1234.json'

        $detailPath = Join-Path $Pages 'data/code-review' $row.detail_file
        $detailPath | Should -Exist
        $detail = Get-Content $detailPath -Raw | ConvertFrom-Json
        $detail.skill | Should -Be 'code-review'
        $detail.pattern | Should -Be 'A'
    }

    It 'appends a second row without losing the first' {
        @(
            @{ ts = "2026-05-29T00:00:00Z"; commit = "aaaa1111000"; score = 50.0 }
            @{ ts = "2026-05-29T01:00:00Z"; commit = "bbbb2222000"; score = 75.0 }
        ) | ForEach-Object {
            $h = @{ schema_version=1; pattern="A"; headline_score=$_.score; status="ok"; adapter="smoke"; trials=1
                   metrics = @{ tp=1; fn=0; case_count=1; required_bug_count=1 } } | ConvertTo-Json -Compress -Depth 5
            [IO.File]::WriteAllText((Join-Path $EvalOut 'headline-score.json'), $h, $Utf8NoBom)
            [IO.File]::WriteAllText((Join-Path $EvalOut 'run-detail.json'),
                (@{ schema_version=1; pattern="A"; detail=@{} } | ConvertTo-Json -Compress), $Utf8NoBom)
            & pwsh -NoProfile -File $WrapPs1 -Skill code-review -EvalOutDir $EvalOut -PagesDir $Pages -Commit $_.commit -Timestamp $_.ts | Out-Null
        }

        $lines = Get-Content (Join-Path $Pages 'data/code-review/history.jsonl')
        $lines.Count | Should -Be 2
        ($lines[0] | ConvertFrom-Json).headline_score | Should -Be 50.0
        ($lines[1] | ConvertFrom-Json).headline_score | Should -Be 75.0
    }

    It 'emits an error row + no detail file when headline-score.json is missing' {
        & pwsh -NoProfile -File $WrapPs1 -Skill code-review -EvalOutDir $EvalOut -PagesDir $Pages -Commit "ffff0000111" -Timestamp "2026-05-29T00:00:00Z" | Out-Null

        $lines = @(Get-Content (Join-Path $Pages 'data/code-review/history.jsonl') | Where-Object { $_ })
        $row = $lines[0] | ConvertFrom-Json
        $row.status | Should -Be 'error'
        $row.headline_score | Should -BeNullOrEmpty
        $row.detail_file | Should -BeNullOrEmpty
        $row.error | Should -Match 'not produced'

        Test-Path (Join-Path $Pages 'data/code-review/runs') | Should -BeTrue
        (Get-ChildItem (Join-Path $Pages 'data/code-review/runs') -File -ErrorAction SilentlyContinue).Count | Should -Be 0
    }

    It 'writes UTF-8 without BOM' {
        $headline = @{ schema_version=1; pattern="A"; headline_score=0; status="ok"; adapter="smoke"; trials=1; metrics=@{ tp=0; fn=0; case_count=0; required_bug_count=0 } } | ConvertTo-Json -Compress -Depth 5
        [IO.File]::WriteAllText((Join-Path $EvalOut 'headline-score.json'), $headline, $Utf8NoBom)
        [IO.File]::WriteAllText((Join-Path $EvalOut 'run-detail.json'), '{"schema_version":1,"pattern":"A","detail":{}}', $Utf8NoBom)
        & pwsh -NoProfile -File $WrapPs1 -Skill code-review -EvalOutDir $EvalOut -PagesDir $Pages -Commit "aaa111" -Timestamp "2026-05-29T00:00:00Z" | Out-Null

        $bytes = [IO.File]::ReadAllBytes((Join-Path $Pages 'data/code-review/history.jsonl'))
        ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) | Should -BeFalse
    }
}

# ============================================================================
# build-manifest.ps1
# ============================================================================

Describe 'build-manifest.ps1' {

    BeforeAll {
        function global:Write-Jsonl {
            param([string] $Path, [string[]] $JsonLines)
            $dir = Split-Path $Path -Parent
            if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            $content = ($JsonLines -join "`n") + "`n"
            $enc = New-Object System.Text.UTF8Encoding($false)
            [IO.File]::WriteAllText($Path, $content, $enc)
        }
    }

    AfterAll {
        Remove-Item Function:\Write-Jsonl -ErrorAction SilentlyContinue
    }

    BeforeEach {
        $script:Pages = New-TempDir
    }
    AfterEach {
        Remove-Item -Recurse -Force $Pages -ErrorAction SilentlyContinue
    }

    It 'emits manifest skipping skills with no history' {
        & pwsh -NoProfile -File $BuildPs1 -PagesDir $Pages | Out-Null
        $m = Get-Content (Join-Path $Pages 'data/manifest.json') -Raw | ConvertFrom-Json
        @($m.skills).Count | Should -Be 0
    }

    It 'computes delta_from_previous correctly' {
        Write-Jsonl (Join-Path $Pages 'data/code-review/history.jsonl') @(
            '{"commit":"a","short_sha":"a","timestamp":"t1","pattern":"A","headline_score":50.0,"status":"ok","adapter":"smoke","detail_file":"runs/x1.json"}',
            '{"commit":"b","short_sha":"b","timestamp":"t2","pattern":"A","headline_score":75.0,"status":"ok","adapter":"smoke","detail_file":"runs/x2.json"}'
        )
        & pwsh -NoProfile -File $BuildPs1 -PagesDir $Pages | Out-Null
        $m = Get-Content (Join-Path $Pages 'data/manifest.json') -Raw | ConvertFrom-Json
        @($m.skills).Count | Should -Be 1
        $m.skills[0].name | Should -Be 'code-review'
        $m.skills[0].latest.headline_score | Should -Be 75.0
        $m.skills[0].latest.delta_from_previous | Should -Be 25.0
        $m.skills[0].run_count | Should -Be 2
    }

    It 'tolerates an error row as the latest entry' {
        Write-Jsonl (Join-Path $Pages 'data/code-review/history.jsonl') @(
            '{"commit":"a","short_sha":"a","timestamp":"t1","pattern":"A","headline_score":50.0,"status":"ok","adapter":"smoke","detail_file":"runs/x1.json"}',
            '{"commit":"b","short_sha":"b","timestamp":"t2","pattern":null,"headline_score":null,"status":"error","error":"oops","detail_file":null}'
        )
        & pwsh -NoProfile -File $BuildPs1 -PagesDir $Pages | Out-Null
        $m = Get-Content (Join-Path $Pages 'data/manifest.json') -Raw | ConvertFrom-Json
        $m.skills[0].latest.status | Should -Be 'error'
        $m.skills[0].latest.delta_from_previous | Should -BeNullOrEmpty
    }
}

# ============================================================================
# evals/code-review/run-eval.ps1 — Pattern A aggregation
# ============================================================================

Describe 'evals/code-review/run-eval.ps1' {

    It 'emits the Pattern A contract files against the smoke adapter' {
        $out = New-TempDir
        try {
            & pwsh -NoProfile -File $RunEvalPs1 -OutDir $out *> $null
            $headlinePath = Join-Path $out 'headline-score.json'
            $detailPath   = Join-Path $out 'run-detail.json'
            $headlinePath | Should -Exist
            $detailPath   | Should -Exist
            $h = Get-Content $headlinePath -Raw | ConvertFrom-Json
            $h.schema_version | Should -Be 1
            $h.pattern        | Should -Be 'A'
            $h.adapter        | Should -Be 'smoke'
            $h.status         | Should -Be 'ok'
            $h.headline_score | Should -BeGreaterOrEqual 0
            $h.headline_score | Should -BeLessOrEqual 100
            $expected = [math]::Round((100.0 * $h.metrics.tp / $h.metrics.required_bug_count), 2)
            $h.headline_score | Should -Be $expected
        } finally {
            Remove-Item -Recurse -Force $out -ErrorAction SilentlyContinue
        }
    }

    It 'reports an error when the adapter does not exist' {
        $out = New-TempDir
        try {
            & pwsh -NoProfile -File $RunEvalPs1 -OutDir $out -Adapter "C:\nope-no-adapter.ps1" *> $null
            $h = Get-Content (Join-Path $out 'headline-score.json') -Raw | ConvertFrom-Json
            $h.status | Should -Be 'error'
            $h.headline_score | Should -BeNullOrEmpty
        } finally {
            Remove-Item -Recurse -Force $out -ErrorAction SilentlyContinue
        }
    }
}
