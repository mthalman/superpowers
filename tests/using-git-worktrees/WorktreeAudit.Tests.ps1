BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:ScriptPath = Join-Path $RepoRoot 'skills' 'using-git-worktrees' 'scripts' 'Get-WorktreeAudit.ps1'

    function script:New-TestRepository {
        $root = Join-Path ([IO.Path]::GetTempPath()) ("worktree-audit-tests-" + [Guid]::NewGuid().ToString('N'))
        $repo = Join-Path $root 'repo'
        $worktree = Join-Path $root 'feature worktree'
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        & git -C $repo init -q -b main
        & git -C $repo config user.email 'tests@example.com'
        & git -C $repo config user.name 'Tests'
        Set-Content -LiteralPath (Join-Path $repo 'README.md') -Value 'initial'
        & git -C $repo add README.md
        & git -C $repo commit -q -m 'initial'
        & git -C $repo worktree add -q -b feature $worktree

        [pscustomobject]@{
            Root     = $root
            Repo     = $repo
            Worktree = $worktree
        }
    }
}

Describe 'Get-WorktreeAudit.ps1' {
    BeforeEach {
        $script:TestRepository = New-TestRepository
    }

    AfterEach {
        if ($script:TestRepository) {
            Remove-Item -LiteralPath $script:TestRepository.Root -Recurse -Force -ErrorAction SilentlyContinue
            $script:TestRepository = $null
        }
    }

    It 'handles worktree paths containing spaces and flags unpublished work' {
        Set-Content -LiteralPath (Join-Path $TestRepository.Worktree 'feature.txt') -Value 'feature'
        & git -C $TestRepository.Worktree add feature.txt
        & git -C $TestRepository.Worktree commit -q -m 'feature candidate'

        $json = & $ScriptPath `
            -RepoPath $TestRepository.Repo `
            -SkipPullRequests `
            -AsJson
        $result = $json | ConvertFrom-Json

        @($result).Count | Should -Be 1
        $result.Worktree | Should -Be ([IO.Path]::GetFullPath($TestRepository.Worktree))
        $result.Branch | Should -Be 'feature'
        $result.RemoteState | Should -Be 'remote-unknown'
        $result.Bucket | Should -Be 'review-unpublished'
    }

    It 'protects tracked work in preference to other signals' {
        Set-Content -LiteralPath (Join-Path $TestRepository.Worktree 'README.md') -Value 'changed'

        $result = (& $ScriptPath `
            -RepoPath $TestRepository.Repo `
            -SkipPullRequests `
            -AsJson) | ConvertFrom-Json

        $result.Dirty | Should -Be 'wip:1'
        $result.Bucket | Should -Be 'hold-wip'
    }

    It 'marks a clean branch reachable from the base as safe' {
        Set-Content -LiteralPath (Join-Path $TestRepository.Worktree 'feature.txt') -Value 'feature'
        & git -C $TestRepository.Worktree add feature.txt
        & git -C $TestRepository.Worktree commit -q -m 'feature'
        & git -C $TestRepository.Repo merge -q --no-ff feature -m 'merge feature'

        $result = (& $ScriptPath `
            -RepoPath $TestRepository.Repo `
            -SkipPullRequests `
            -AsJson) | ConvertFrom-Json

        $result.MergeState | Should -Be 'reachable-from-base'
        $result.Bucket | Should -Be 'safe-merged'
    }

    It 'does not treat a closed unmerged pull request as safe' {
        Set-Content -LiteralPath (Join-Path $TestRepository.Worktree 'closed.txt') -Value 'closed'
        & git -C $TestRepository.Worktree add closed.txt
        & git -C $TestRepository.Worktree commit -q -m 'closed candidate'
        $head = (& git -C $TestRepository.Worktree rev-parse HEAD).Trim()
        $fixture = Join-Path $TestRepository.Root 'pull-requests.json'
        @(
            @{
                number      = 42
                state       = 'CLOSED'
                headRefName = 'feature'
                headRefOid  = $head
                mergedAt    = $null
                url         = 'https://github.example/pull/42'
            }
        ) | ConvertTo-Json | Set-Content -LiteralPath $fixture -Encoding utf8NoBOM

        $result = (& $ScriptPath `
            -RepoPath $TestRepository.Repo `
            -PullRequestDataPath $fixture `
            -AsJson) | ConvertFrom-Json

        $result.PullRequestState | Should -Be 'CLOSED'
        $result.Bucket | Should -Be 'review-closed-pr'
    }

    It 'accepts a merged pull request only when it covers the current head' {
        Set-Content -LiteralPath (Join-Path $TestRepository.Worktree 'merged.txt') -Value 'merged'
        & git -C $TestRepository.Worktree add merged.txt
        & git -C $TestRepository.Worktree commit -q -m 'merged candidate'
        $head = (& git -C $TestRepository.Worktree rev-parse HEAD).Trim()
        $fixture = Join-Path $TestRepository.Root 'pull-requests.json'
        @(
            @{
                number      = 43
                state       = 'MERGED'
                headRefName = 'feature'
                headRefOid  = $head
                mergedAt    = '2026-08-27T00:00:00Z'
                url         = 'https://github.example/pull/43'
            }
        ) | ConvertTo-Json | Set-Content -LiteralPath $fixture -Encoding utf8NoBOM

        $result = (& $ScriptPath `
            -RepoPath $TestRepository.Repo `
            -PullRequestDataPath $fixture `
            -AsJson) | ConvertFrom-Json

        $result.MergeState | Should -Be 'merged-pr-covers-head'
        $result.Bucket | Should -Be 'safe-merged'
    }

    It 'reports a missing worktree conservatively instead of aborting' {
        Remove-Item -LiteralPath $TestRepository.Worktree -Recurse -Force

        $result = (& $ScriptPath `
            -RepoPath $TestRepository.Repo `
            -SkipPullRequests `
            -AsJson) | ConvertFrom-Json

        $result.Prunable | Should -BeTrue
        $result.Bucket | Should -Be 'review-prunable'
    }

    It 'holds a locked worktree even when its head is reachable from base' {
        & git -C $TestRepository.Repo worktree lock --reason 'active external process' $TestRepository.Worktree

        $result = (& $ScriptPath `
            -RepoPath $TestRepository.Repo `
            -SkipPullRequests `
            -AsJson) | ConvertFrom-Json

        $result.Locked | Should -BeTrue
        $result.Note | Should -Be 'active external process'
        $result.Bucket | Should -Be 'hold-locked'
    }

    It 'requires an explicit base when no default branch can be proven' {
        & git -C $TestRepository.Repo branch -m main trunk

        {
            & $ScriptPath `
                -RepoPath $TestRepository.Repo `
                -SkipPullRequests `
                -AsJson
        } | Should -Throw '*Pass -BaseBranch explicitly*'
    }

    It 'requires an explicit base when main and master both exist' {
        & git -C $TestRepository.Repo branch master

        {
            & $ScriptPath `
                -RepoPath $TestRepository.Repo `
                -SkipPullRequests `
                -AsJson
        } | Should -Throw '*Pass -BaseBranch explicitly*'

        {
            & $ScriptPath `
                -RepoPath $TestRepository.Repo `
                -BaseBranch main `
                -SkipPullRequests `
                -AsJson
        } | Should -Not -Throw
    }

    It 'detects submodule changes even when the repository ignores them' {
        $submoduleSource = Join-Path $TestRepository.Root 'submodule-source'
        New-Item -ItemType Directory -Path $submoduleSource | Out-Null
        & git -C $submoduleSource init -q -b main
        & git -C $submoduleSource config user.email 'tests@example.com'
        & git -C $submoduleSource config user.name 'Tests'
        Set-Content -LiteralPath (Join-Path $submoduleSource 'data.txt') -Value 'initial'
        & git -C $submoduleSource add data.txt
        & git -C $submoduleSource commit -q -m 'initial'

        & git -c protocol.file.allow=always -C $TestRepository.Worktree `
            submodule add -q $submoduleSource 'modules/sample'
        & git -C $TestRepository.Worktree config -f .gitmodules submodule.modules/sample.ignore all
        & git -C $TestRepository.Worktree add .gitmodules modules/sample
        & git -C $TestRepository.Worktree commit -q -m 'add submodule'
        Set-Content -LiteralPath (Join-Path $TestRepository.Worktree 'modules' 'sample' 'data.txt') -Value 'changed'

        $result = (& $ScriptPath `
            -RepoPath $TestRepository.Repo `
            -SkipPullRequests `
            -AsJson) | ConvertFrom-Json

        $result.Dirty | Should -Be 'wip:1'
        $result.Bucket | Should -Be 'hold-wip'
    }

    It 'does not classify assume-unchanged files as safe' {
        & git -C $TestRepository.Worktree update-index --assume-unchanged README.md
        Set-Content -LiteralPath (Join-Path $TestRepository.Worktree 'README.md') -Value 'hidden change'

        $result = (& $ScriptPath `
            -RepoPath $TestRepository.Repo `
            -SkipPullRequests `
            -AsJson) | ConvertFrom-Json

        $result.Dirty | Should -Be 'index-flags:1'
        $result.AssumeUnchanged | Should -Be 1
        $result.Bucket | Should -Be 'review-index-flags'
    }

    It 'does not classify skip-worktree files as safe' {
        & git -C $TestRepository.Worktree update-index --skip-worktree README.md
        Set-Content -LiteralPath (Join-Path $TestRepository.Worktree 'README.md') -Value 'hidden change'

        $result = (& $ScriptPath `
            -RepoPath $TestRepository.Repo `
            -SkipPullRequests `
            -AsJson) | ConvertFrom-Json

        $result.Dirty | Should -Be 'index-flags:1'
        $result.SkipWorktree | Should -Be 1
        $result.Bucket | Should -Be 'review-index-flags'
    }

    It 'does not refresh the worktree index during an audit' {
        $indexPath = (& git -C $TestRepository.Worktree rev-parse --git-path index).Trim()
        $before = (Get-Item -LiteralPath $indexPath).LastWriteTimeUtc

        & $ScriptPath `
            -RepoPath $TestRepository.Repo `
            -SkipPullRequests `
            -AsJson | Out-Null

        (Get-Item -LiteralPath $indexPath).LastWriteTimeUtc | Should -Be $before
    }

    It 'reports whether optional size collection was complete' {
        $result = (& $ScriptPath `
            -RepoPath $TestRepository.Repo `
            -SkipPullRequests `
            -IncludeSize `
            -AsJson) | ConvertFrom-Json

        $result.SizeBytes | Should -BeGreaterThan 0
        $result.SizeComplete | Should -BeTrue
    }

    It 'does not report safe when GitHub PR lookup fails' {
        & git -C $TestRepository.Repo remote add origin 'https://github.com/example/worktree-audit-test.git'
        function global:gh {
            $global:LASTEXITCODE = 1
            'simulated failure'
        }

        try {
            $warnings = @()
            $result = (& $ScriptPath `
                -RepoPath $TestRepository.Repo `
                -RemoteName origin `
                -BaseBranch main `
                -WarningVariable warnings `
                -AsJson) | ConvertFrom-Json
        }
        finally {
            Remove-Item -LiteralPath Function:\global:gh -ErrorAction SilentlyContinue
        }

        $warnings | Should -Not -BeNullOrEmpty
        $result.PullRequestLookup | Should -Be 'unavailable'
        $result.PullRequestState | Should -Be 'unknown'
        $result.Bucket | Should -Be 'review-pr-unknown'
    }
}
