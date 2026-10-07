BeforeAll {
    $script:Helper = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'skills\manual-worktree-session\scripts\Initialize-ManualWorktree.ps1'
    function script:Invoke-Helper {
        param([string] $Action = 'Create', [hashtable] $Extra = @{})
        $params = @{ Action = $Action; StatePath = $script:StatePath }
        if ($Action -eq 'Create') {
            $params.RepoPath = $script:Repo
            $params.WorktreePath = $script:Worktree
            $params.Branch = 'manual-test'
        }
        foreach ($key in $Extra.Keys) { $params[$key] = $Extra[$key] }
        (& $script:Helper @params) | ConvertFrom-Json
    }
    function script:Set-FailedState {
        $state = Get-Content -LiteralPath $script:StatePath -Raw | ConvertFrom-Json
        $state.phase = 'failed'
        $state | ConvertTo-Json | Set-Content -LiteralPath $script:StatePath -Encoding utf8NoBOM
    }
    function script:Get-WorktreeGitDirectory {
        (& git -C $script:Worktree rev-parse --absolute-git-dir).Trim()
    }
}

Describe 'Manual worktree initialization' {
    BeforeEach {
        $script:Root = Join-Path ([IO.Path]::GetTempPath()) ('manual-session-tests-' + [Guid]::NewGuid().ToString('N'))
        $script:Repo = Join-Path $script:Root 'source repo'
        $script:Worktree = Join-Path $script:Root 'child worktree'
        $script:StatePath = Join-Path $script:Root 'operation.json'
        New-Item -ItemType Directory -Path $script:Repo | Out-Null
        & git -C $script:Repo init -q -b main
        & git -C $script:Repo config user.email 'tests@example.com'
        & git -C $script:Repo config user.name 'Tests'
        & git -C $script:Repo config core.autocrlf false
        [IO.File]::WriteAllText((Join-Path $script:Repo 'tracked.txt'), "original`n")
        [IO.File]::WriteAllBytes((Join-Path $script:Repo 'binary file.bin'), [byte[]]@(0, 255, 128, 10, 13))
        $script:UnicodeName = "space $([char]0x03bb) [brackets].txt"
        [IO.File]::WriteAllText((Join-Path $script:Repo $script:UnicodeName), "unicode filename`n")
        [IO.File]::WriteAllText((Join-Path $script:Repo '.gitignore'), "*.ignored`n")
        & git -C $script:Repo add .
        & git -C $script:Repo commit -q -m 'fixture'
        $script:Commit = (& git -C $script:Repo rev-parse HEAD).Trim()
        $script:Confirm = @{ FailedInitializationConfirmed = $true; SessionStopped = $true; NoActiveWriter = $true }
    }

    AfterEach {
        if ($script:Root -and (Test-Path -LiteralPath $script:Root)) {
            foreach ($file in [IO.Directory]::EnumerateFiles($script:Root, '*', [IO.SearchOption]::AllDirectories)) {
                [IO.File]::SetAttributes($file, [IO.FileAttributes]::Normal)
            }
            [IO.Directory]::Delete($script:Root, $true)
        }
    }

    It 'creates and verifies a pinned worktree without touching dirty source files or configuration' {
        [IO.File]::WriteAllText((Join-Path $script:Repo 'tracked.txt'), 'dirty source')
        [IO.File]::WriteAllText((Join-Path $script:Repo 'untracked.txt'), 'scratch')
        & git -C $script:Repo config core.fsmonitor false
        $before = (& git -C $script:Repo status --porcelain) -join "`n"
        $config = Get-Content -LiteralPath (Join-Path $script:Repo '.git\config') -Raw
        $result = Invoke-Helper
        $result.status | Should -Be 'ready'
        $result.commit | Should -Be $script:Commit
        $result.worktree_path | Should -Be $script:Worktree
        (Invoke-Helper Verify).status | Should -Be 'ready'
        ((& git -C $script:Repo status --porcelain) -join "`n") | Should -Be $before
        (Get-Content -LiteralPath (Join-Path $script:Repo '.git\config') -Raw) | Should -Be $config
        (& git -C $script:Repo branch --show-current) | Should -Be 'main'
        (Get-Content -LiteralPath (Join-Path $script:Worktree 'tracked.txt') -Raw) | Should -Be "original`n"
        (Get-Content -LiteralPath $script:StatePath -Raw | ConvertFrom-Json).phase | Should -Be 'ready'
    }

    It 'does not run checkout hooks' {
        $marker = Join-Path $script:Repo 'hook-marker'
        $hook = Join-Path $script:Repo '.git\hooks\post-checkout'
        [IO.File]::WriteAllText($hook, "#!/bin/sh`ntouch hook-marker`n")
        (Invoke-Helper).status | Should -Be 'ready'
        Test-Path -LiteralPath $marker | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $script:Worktree 'hook-marker') | Should -BeFalse
    }

    It 'refuses existing paths, overlapping checkouts and reused branches' {
        { Invoke-Helper -Extra @{ WorktreePath = $script:Repo } } | Should -Throw '*Target must not exist*'
        { Invoke-Helper -Extra @{ WorktreePath = (Join-Path $script:Repo 'nested') } } | Should -Throw '*overlaps*'
        & git -C $script:Repo branch manual-test
        { Invoke-Helper } | Should -Throw '*already exists*'
        Test-Path -LiteralPath $script:Worktree | Should -BeFalse
    }

    It 'refuses state in the source checkout and invalid start points' {
        { & $script:Helper -Action Create -RepoPath $script:Repo -WorktreePath $script:Worktree -Branch new `
            -StatePath (Join-Path $script:Repo 'state.json') } | Should -Throw '*outside*'
        { Invoke-Helper -Extra @{ StartPoint = 'does-not-exist' } } | Should -Throw '*exited*'
        Test-Path -LiteralPath $script:Worktree | Should -BeFalse
    }

    It 'preserves unrelated registered worktrees' {
        $other = Join-Path $script:Root 'other checkout'
        & git -C $script:Repo worktree add -q -b unrelated $other
        [IO.File]::WriteAllText((Join-Path $other 'tracked.txt'), 'unrelated edit')
        (Invoke-Helper).status | Should -Be 'ready'
        (Get-Content -LiteralPath (Join-Path $other 'tracked.txt') -Raw) | Should -Be 'unrelated edit'
        (& git -C $other branch --show-current) | Should -Be 'unrelated'
    }

    It 'refuses duplicate creation but allows verification without recreating' {
        Invoke-Helper | Out-Null
        { Invoke-Helper } | Should -Throw '*State already exists*'
        (Invoke-Helper Verify).status | Should -Be 'ready'
    }

    It 'keeps a nonempty unrelated state guard file intact' {
        [IO.File]::WriteAllText("$script:StatePath.lock", 'do not delete')
        { Invoke-Helper } | Should -Throw '*Nonempty state guard*'
        (Get-Content -LiteralPath "$script:StatePath.lock" -Raw) | Should -Be 'do not delete'
        Test-Path -LiteralPath $script:StatePath | Should -BeFalse
        Test-Path -LiteralPath $script:Worktree | Should -BeFalse
    }

    It 'uses an explicit start commit instead of the current source HEAD' {
        [IO.File]::WriteAllText((Join-Path $script:Repo 'tracked.txt'), 'later')
        & git -C $script:Repo add tracked.txt
        & git -C $script:Repo commit -q -m 'advance source'
        (Invoke-Helper -Extra @{ StartPoint = $script:Commit }).commit | Should -Be $script:Commit
        (Get-Content -LiteralPath (Join-Path $script:Worktree 'tracked.txt') -Raw) | Should -Be "original`n"
    }

    It 'refuses submodule trees rather than claiming a complete checkout' {
        & git -C $script:Repo update-index --add --cacheinfo "160000,$script:Commit,module"
        & git -C $script:Repo commit -q -m 'gitlink fixture'
        { Invoke-Helper } | Should -Throw '*Submodule checkouts*'
        Test-Path -LiteralPath $script:Worktree | Should -BeFalse
    }

    It 'detects missing files, wrong HEAD, dirty files, and index flags' {
        Invoke-Helper | Out-Null
        [IO.File]::Delete((Join-Path $script:Worktree 'tracked.txt'))
        { Invoke-Helper Verify } | Should -Throw '*missing files*'
        & git -C $script:Worktree checkout-index tracked.txt
        & git -C $script:Worktree update-index --assume-unchanged tracked.txt
        { Invoke-Helper Verify } | Should -Throw '*Index flags*'
        & git -C $script:Worktree update-index --no-assume-unchanged tracked.txt
        [IO.File]::WriteAllText((Join-Path $script:Worktree 'tracked.txt'), 'changed')
        { Invoke-Helper Verify } | Should -Throw '*unexpected*'
        & git -C $script:Worktree add tracked.txt
        & git -C $script:Worktree commit -q -m 'advance'
        { Invoke-Helper Verify } | Should -Throw '*Branch or HEAD*'
    }

    It 'rejects initialization locks and concurrent helper operations' {
        Invoke-Helper | Out-Null
        $lock = Join-Path (Get-WorktreeGitDirectory) 'index.lock'
        [IO.File]::WriteAllBytes($lock, [byte[]]@())
        { Invoke-Helper Verify } | Should -Throw '*lock exists*'
        [IO.File]::Delete($lock)
        $guard = [IO.File]::Open("$script:StatePath.lock", 'OpenOrCreate', 'ReadWrite', 'None')
        try { { Invoke-Helper Verify } | Should -Throw }
        finally { $guard.Dispose() }
    }

    It 'requires all recovery attestations and refuses previously ready worktrees' {
        Invoke-Helper | Out-Null
        { Invoke-Helper Recover $script:Confirm } | Should -Throw '*previously ready*'
        Set-FailedState
        { Invoke-Helper Recover } | Should -Throw '*requires confirmed*'
        { Invoke-Helper Recover @{ FailedInitializationConfirmed = $true; SessionStopped = $true } } | Should -Throw '*requires confirmed*'
    }

    It 'recovers absent index, missing Unicode/binary files, and a zero-byte stale lock' {
        Invoke-Helper | Out-Null
        Set-FailedState
        $dir = Get-WorktreeGitDirectory
        [IO.File]::Delete((Join-Path $dir 'index'))
        [IO.File]::Delete((Join-Path $script:Worktree $script:UnicodeName))
        [IO.File]::Delete((Join-Path $script:Worktree 'binary file.bin'))
        [IO.File]::WriteAllBytes((Join-Path $dir 'index.lock'), [byte[]]@())
        (Invoke-Helper Recover $script:Confirm).status | Should -Be 'ready'
        (Invoke-Helper Verify).status | Should -Be 'ready'
        [Convert]::ToHexString([IO.File]::ReadAllBytes((Join-Path $script:Worktree 'binary file.bin'))) | Should -Be '00FF800A0D'
        Test-Path -LiteralPath (Join-Path $script:Worktree $script:UnicodeName) | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $dir 'index.lock') | Should -BeFalse
    }

    It 'recovers an empty partial index with staged deletions and untracked tracked copies' {
        Invoke-Helper | Out-Null
        Set-FailedState
        & git -C $script:Worktree read-tree --empty
        [IO.File]::Delete((Join-Path $script:Worktree 'tracked.txt'))
        (Invoke-Helper Recover $script:Confirm).status | Should -Be 'ready'
        (Get-Content -LiteralPath (Join-Path $script:Worktree 'tracked.txt') -Raw) | Should -Be "original`n"
    }

    It 'refuses recovery with surviving edits and preserves the existing index and lock' {
        Invoke-Helper | Out-Null
        Set-FailedState
        $dir = Get-WorktreeGitDirectory
        $index = [Convert]::ToHexString([IO.File]::ReadAllBytes((Join-Path $dir 'index')))
        [IO.File]::WriteAllText((Join-Path $script:Worktree 'tracked.txt'), 'user work')
        [IO.File]::WriteAllBytes((Join-Path $dir 'index.lock'), [byte[]]@())
        { Invoke-Helper Recover $script:Confirm } | Should -Throw '*Surviving tracked files*'
        [Convert]::ToHexString([IO.File]::ReadAllBytes((Join-Path $dir 'index'))) | Should -Be $index
        Test-Path -LiteralPath (Join-Path $dir 'index.lock') | Should -BeTrue
        (Get-Content -LiteralPath (Join-Path $script:Worktree 'tracked.txt') -Raw) | Should -Be 'user work'
    }

    It 'refuses recovery when a missing tracked file has a reparse-point parent' {
        $nested = Join-Path $script:Repo nested
        [IO.Directory]::CreateDirectory($nested) | Out-Null
        [IO.File]::WriteAllText((Join-Path $nested tracked.txt), 'tracked content')
        & git -C $script:Repo add nested/tracked.txt
        & git -C $script:Repo commit -q -m 'add nested tracked file'
        $outside = Join-Path $script:Root outside
        [IO.Directory]::CreateDirectory($outside) | Out-Null

        Invoke-Helper | Out-Null
        Set-FailedState
        [IO.Directory]::Delete((Join-Path $script:Worktree nested), $true)
        New-Item -ItemType Junction -Path (Join-Path $script:Worktree nested) -Target $outside | Out-Null
        try {
            { Invoke-Helper Recover $script:Confirm } | Should -Throw '*reparse-point ancestor*'
            Test-Path -LiteralPath (Join-Path $outside tracked.txt) | Should -BeFalse
            (Get-Item -LiteralPath (Join-Path $script:Worktree nested)).Attributes.HasFlag([IO.FileAttributes]::ReparsePoint) | Should -BeTrue
        }
        finally {
            [IO.Directory]::Delete((Join-Path $script:Worktree nested))
        }
    }

    It 'refuses unknown ignored files and staged modifications' {
        Invoke-Helper | Out-Null
        Set-FailedState
        $extra = Join-Path $script:Worktree 'scratch.ignored'
        [IO.File]::WriteAllText($extra, 'unknown')
        { Invoke-Helper Recover $script:Confirm } | Should -Throw '*Unexpected files*'
        [IO.File]::Delete($extra)
        [IO.File]::WriteAllText((Join-Path $script:Worktree 'tracked.txt'), 'staged work')
        & git -C $script:Worktree add tracked.txt
        [IO.File]::WriteAllText((Join-Path $script:Worktree 'tracked.txt'), "original`n")
        { Invoke-Helper Recover $script:Confirm } | Should -Throw '*Staged edits*'
    }

    It 'refuses nonempty and actively held locks without removing them' {
        Invoke-Helper | Out-Null
        Set-FailedState
        $lock = Join-Path (Get-WorktreeGitDirectory) 'index.lock'
        [IO.File]::WriteAllText($lock, 'writer')
        { Invoke-Helper Recover $script:Confirm } | Should -Throw '*Nonempty*'
        (Get-Content -LiteralPath $lock -Raw) | Should -Be 'writer'
        [IO.File]::WriteAllBytes($lock, [byte[]]@())
        $handle = [IO.File]::Open($lock, 'Open', 'ReadWrite', 'None')
        try { { Invoke-Helper Recover $script:Confirm } | Should -Throw }
        finally { $handle.Dispose() }
        Test-Path -LiteralPath $lock | Should -BeTrue
    }

    It 'refuses corrupt indexes without rebuilding them' {
        Invoke-Helper | Out-Null
        Set-FailedState
        $index = Join-Path (Get-WorktreeGitDirectory) 'index'
        [IO.File]::WriteAllText($index, 'corrupt index')
        { Invoke-Helper Recover $script:Confirm } | Should -Throw '*exited*'
        (Get-Content -LiteralPath $index -Raw) | Should -Be 'corrupt index'
    }

    It 'does not recover arbitrary existing worktrees without initialization state' {
        & git -C $script:Repo worktree add -q -b manual-test $script:Worktree
        { Invoke-Helper Recover $script:Confirm } | Should -Throw '*state does not exist*'
        (& git -C $script:Worktree status --porcelain) | Should -BeNullOrEmpty
    }

    It 'emits error JSON and a nonzero process exit on failure' {
        $output = @(& (Get-Command pwsh -CommandType Application | Select-Object -First 1).Source `
            -NoProfile -File $script:Helper -Action Verify -StatePath $script:StatePath 2>$null)
        $LASTEXITCODE | Should -Not -Be 0
        ($output[0] | ConvertFrom-Json).status | Should -Be 'error'
    }

    It 'refuses repository-routing environment variables' {
        $previous = $env:GIT_INDEX_FILE
        try {
            $env:GIT_INDEX_FILE = Join-Path $script:Root 'foreign-index'
            { Invoke-Helper } | Should -Throw '*repository-routing*'
            Test-Path -LiteralPath $script:Worktree | Should -BeFalse
        }
        finally { $env:GIT_INDEX_FILE = $previous }
    }
}
