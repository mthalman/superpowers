BeforeDiscovery {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $skillsRoot = Join-Path $repoRoot 'skills'

    $script:SkillCases = @(
        Get-ChildItem -LiteralPath $skillsRoot -Filter 'SKILL.md' -File -Recurse | ForEach-Object {
            $skillRoot = $_.Directory.FullName
            @{
                Name      = $skillRoot.Substring($skillsRoot.Length + 1).Replace('\', '/')
                SkillRoot = $skillRoot
            }
        }
    )
}

BeforeAll {
    # Paths a skill tells the agent to open: backticked bundled-resource paths
    # and relative Markdown link targets.
    $script:BacktickPathPattern = '`((?:\.\./)*(?:references|scripts|assets)/[^`\s]+)`'
    $script:LinkPattern = '\]\(([^)\s]+)\)'
    $script:FencePattern = '(?ms)^[ \t]*(`{3,}|~{3,}).*?^[ \t]*\1[ \t]*\r?$'

    # Prose that names a path as an illustration rather than a bundled file.
    $script:IllustrativePaths = @(
        'skill-reviewer|references/review-criteria.md|references/x.md'
        'skill-reviewer|references/review-criteria.md|references/aws.md'
    )

    function Get-BrokenSkillPaths {
        param([string]$SkillRoot, [string]$Name)

        $broken = [System.Collections.Generic.List[string]]::new()
        $markdownFiles = Get-ChildItem -LiteralPath $SkillRoot -Filter '*.md' -File -Recurse

        foreach ($file in $markdownFiles) {
            $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding utf8
            if (-not $text) { continue }
            # Fenced blocks hold examples of other documents, not paths to open.
            $text = [regex]::Replace($text, $FencePattern, '')
            $fileDir = $file.Directory.FullName
            $relativeFile = $file.FullName.Substring($SkillRoot.Length + 1).Replace('\', '/')

            foreach ($match in [regex]::Matches($text, $BacktickPathPattern)) {
                $target = $match.Groups[1].Value
                # Skip placeholders and globs such as references/<name>.md or scripts/*.ps1.
                if ($target -match '[<>*{}…]|\.\.\.') { continue }
                if ($IllustrativePaths -contains "$Name|$relativeFile|$target") { continue }
                $target = ($target -split '[#:]', 2)[0].TrimEnd('.', ',', ';')
                $fromFile = Join-Path $fileDir $target
                $fromRoot = Join-Path $SkillRoot $target
                if (-not (Test-Path -LiteralPath $fromFile) -and -not (Test-Path -LiteralPath $fromRoot)) {
                    $broken.Add("${relativeFile}: $target")
                }
            }

            foreach ($match in [regex]::Matches($text, $LinkPattern)) {
                $target = $match.Groups[1].Value
                if ($target -match '^(?:[a-z][a-z0-9+.-]*:|#|/)' -or $target -match '[<>*{}]') { continue }
                $target = [uri]::UnescapeDataString(($target -split '#', 2)[0])
                if (-not $target) { continue }
                if (-not (Test-Path -LiteralPath (Join-Path $fileDir $target))) {
                    $broken.Add("${relativeFile}: $target")
                }
            }
        }

        return $broken.ToArray()
    }
}

Describe 'Skill bundled-resource paths' {
    It 'detects missing referenced files and ignores fenced examples' {
        $root = Join-Path $TestDrive 'demo-skill'
        New-Item -ItemType Directory -Path (Join-Path $root 'references') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'references' 'present.md') -Value '# Present'
        Set-Content -LiteralPath (Join-Path $root 'SKILL.md') -Value @(
            'Open `references/present.md` when needed.'
            'Open `references/missing.md` when needed.'
            'See [gone](references/gone.md).'
            '```markdown'
            '[example](not/real.md)'
            '```'
        )

        $broken = @(Get-BrokenSkillPaths -SkillRoot $root -Name 'demo-skill')

        $broken | Should -Be @('SKILL.md: references/missing.md', 'SKILL.md: references/gone.md')
    }

    It '<Name> references only files that exist' -ForEach $SkillCases {
        $broken = @(Get-BrokenSkillPaths -SkillRoot $SkillRoot -Name $Name)
        $broken | Should -BeNullOrEmpty -Because "these paths are referenced but missing: $($broken -join '; ')"
    }
}
