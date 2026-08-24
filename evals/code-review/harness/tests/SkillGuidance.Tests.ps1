BeforeAll {
    $repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')
    $skillPath = Join-Path $repoRoot 'skills\code-review\SKILL.md'
    $script:SkillText = Get-Content -LiteralPath $skillPath -Raw -Encoding utf8
}

Describe 'code-review evidence policy' {
    It 'uses evidence to drive finding discovery' {
        $orientation = $SkillText.IndexOf('Build an evidence model before generating hypotheses')
        $hypotheses = $SkillText.IndexOf('Generate hypotheses from')
        $orientation | Should -BeGreaterOrEqual 0
        $hypotheses | Should -BeGreaterThan $orientation
        $SkillText | Should -Match 'risk-directed research'
        $SkillText | Should -Match 'authoritative reference documentation'
    }

    It 'requires verified behavior and impact for findings' {
        $SkillText | Should -Match 'verified findings'
        $SkillText | Should -Match 'causal claim and impact'
        $SkillText | Should -Match 'verdict.*only.*verified findings'
    }

    It 'keeps unresolved questions separate from findings and verdicts' {
        $SkillText | Should -Match 'Questions are not findings'
        $SkillText | Should -Match 'must not affect severity or verdict'
    }

    It 'does not retain conflicting speculative-review guidance' {
        $SkillText | Should -Not -Match 'flag concerns even when unsure'
        $SkillText | Should -Not -Match 'Surface plausible risks even if you can''t fully confirm them'
        $SkillText | Should -Not -Match 'surface it as a low-confidence question'
        $SkillText | Should -Not -Match 'present both perspectives and mark the finding as needing human judgment'
        $SkillText | Should -Not -Match 'downgrade severity or convert the finding to a question'
        $SkillText | Should -Not -Match 'When uncertain, always escalate'
        $SkillText | Should -Not -Match 'Any "unsure".*Needs Human Review'
    }
}
