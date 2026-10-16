BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:ClaudeManifest = Get-Content -LiteralPath (Join-Path $RepoRoot '.claude-plugin\plugin.json') -Raw |
        ConvertFrom-Json
    $script:CodexManifest = Get-Content -LiteralPath (Join-Path $RepoRoot '.codex-plugin\plugin.json') -Raw |
        ConvertFrom-Json
    $script:ClaudeMarketplace = Get-Content -LiteralPath (Join-Path $RepoRoot '.claude-plugin\marketplace.json') -Raw |
        ConvertFrom-Json
    $script:CodexMarketplace = Get-Content -LiteralPath (Join-Path $RepoRoot '.agents\plugins\marketplace.json') -Raw |
        ConvertFrom-Json
    $script:VersionConfig = Get-Content -LiteralPath (Join-Path $RepoRoot '.version-bump.json') -Raw |
        ConvertFrom-Json
}

Describe 'Shared plugin scaffold' {
    It 'uses matching client-neutral plugin manifests' {
        $ClaudeManifest.name | Should -Be 'agents'
        $CodexManifest.name | Should -Be $ClaudeManifest.name
        $ClaudeManifest.version | Should -Match '^\d+\.\d+\.\d+$'
        $CodexManifest.version | Should -Be $ClaudeManifest.version
        $ClaudeManifest.description | Should -Be 'Shared AI skills for Claude Code, GitHub Copilot CLI, and OpenAI Codex.'
        $CodexManifest.description | Should -Be $ClaudeManifest.description
    }

    It 'discovers the same root-level skills directory in both clients' {
        $ClaudeManifest.skills | Should -Be './skills/'
        $CodexManifest.skills | Should -Be $ClaudeManifest.skills
        Test-Path -LiteralPath (Join-Path $RepoRoot $ClaudeManifest.skills) -PathType Container |
            Should -BeTrue
        @(Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'skills') -Filter 'SKILL.md' -File -Recurse).Count |
            Should -BeGreaterThan 0
    }

    It 'registers the repository root in the Claude marketplace' {
        $ClaudeMarketplace.name | Should -Be 'agents'
        $ClaudeMarketplace.owner.name | Should -Be 'mthalman'
        @($ClaudeMarketplace.plugins).Count | Should -Be 1
        $ClaudeMarketplace.plugins[0].name | Should -Be $ClaudeManifest.name
        $ClaudeMarketplace.plugins[0].source | Should -Be './'
        $ClaudeMarketplace.plugins[0].description | Should -Be $ClaudeManifest.description
    }

    It 'registers the repository root in the Codex marketplace' {
        $CodexMarketplace.name | Should -Be 'agents'
        $CodexMarketplace.interface.displayName | Should -Be 'Agents'
        @($CodexMarketplace.plugins).Count | Should -Be 1
        $CodexMarketplace.plugins[0].name | Should -Be $CodexManifest.name
        $CodexMarketplace.plugins[0].source.source | Should -Be 'local'
        $CodexMarketplace.plugins[0].source.path | Should -Be './'
        $CodexMarketplace.plugins[0].policy.installation | Should -Be 'AVAILABLE'
        $CodexMarketplace.plugins[0].policy.authentication | Should -Be 'ON_INSTALL'
        $CodexMarketplace.plugins[0].category | Should -Be 'Productivity'
    }

    It 'bumps only the two versioned plugin manifests' {
        @($VersionConfig.files).Count | Should -Be 2
        @($VersionConfig.files.path | Sort-Object) | Should -Be @(
            '.claude-plugin/plugin.json'
            '.codex-plugin/plugin.json'
        )
        foreach ($file in $VersionConfig.files) {
            $file.field | Should -Be 'version'
            Test-Path -LiteralPath (Join-Path $RepoRoot $file.path) -PathType Leaf | Should -BeTrue
        }
    }
}
