BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:SkillRoot = Join-Path $RepoRoot 'skills' 'markdown-toolkit' 'markdown-toolkit'
    $script:SkillPath = Join-Path $SkillRoot 'SKILL.md'
    $script:ReferencePath = Join-Path $SkillRoot 'references' 'gfm-style-guide.md'
    $script:ValidatorPath = Join-Path $SkillRoot 'scripts' 'validate_markdown.sh'
    $script:TempRoot = Join-Path ([IO.Path]::GetTempPath()) ("markdown-toolkit-tests-" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $TempRoot | Out-Null
}

AfterAll {
    Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Markdown Toolkit' {
    It 'resolves the validator from the loaded skill root' {
        $content = Get-Content -LiteralPath $SkillPath -Raw

        $content | Should -Match 'SKILL_ROOT="<loaded markdown-toolkit directory>"'
        $content | Should -Not -Match 'bash scripts/validate_markdown\.sh'
    }

    It 'keeps nested template fences valid' {
        $content = Get-Content -LiteralPath $ReferencePath -Raw
        $afterTemplatesHeading = ($content -split '## Common Document Templates', 2)[1]
        $templates = ($afterTemplatesHeading -split '## GFM-Specific Features', 2)[0]

        @([regex]::Matches($templates, '(?m)^````markdown\r?$')).Count | Should -Be 3
        @([regex]::Matches($templates, '(?m)^````\r?$')).Count | Should -Be 3
    }

    It 'lists every major reference section in the table of contents' {
        $content = Get-Content -LiteralPath $ReferencePath -Raw

        foreach ($anchor in 'gfm-specific-features', 'common-mistakes-to-avoid', 'validation-and-linting', 'additional-resources') {
            $content | Should -Match ([regex]::Escape("(#$anchor)"))
        }
    }

    It 'has valid Bash syntax' {
        & bash -n $ValidatorPath
        $LASTEXITCODE | Should -Be 0
    }

    It 'uses a project-local markdownlint binary when available' {
        $binDir = Join-Path $TempRoot 'node_modules' '.bin'
        New-Item -ItemType Directory -Path $binDir -Force | Out-Null
        $fakeMarkdownlint = Join-Path $binDir 'markdownlint'
        $fakeContent = @'
#!/usr/bin/env bash
printf '%s\n' "$@" > markdownlint-args.txt
'@
        [IO.File]::WriteAllText(
            $fakeMarkdownlint,
            $fakeContent,
            [Text.UTF8Encoding]::new($false)
        )
        Set-Content -LiteralPath (Join-Path $TempRoot 'README.md') -Value '# Test'

        $bashFakePath = $fakeMarkdownlint.Replace('\', '/')
        & bash -c "chmod +x '$bashFakePath'"
        $LASTEXITCODE | Should -Be 0

        Push-Location $TempRoot
        try {
            $bashValidatorPath = $ValidatorPath.Replace('\', '/')
            & bash $bashValidatorPath 'README.md'
            $LASTEXITCODE | Should -Be 0
        }
        finally {
            Pop-Location
        }

        $arguments = Get-Content -LiteralPath (Join-Path $TempRoot 'markdownlint-args.txt')
        $arguments | Should -Contain '--config'
        $arguments | Should -Contain 'README.md'
    }
}
