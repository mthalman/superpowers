#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Create', 'Verify', 'Recover')][string] $Action,
    [Parameter(Mandatory)][string] $StatePath,
    [string] $RepoPath,
    [string] $WorktreePath,
    [string] $Branch,
    [string] $StartPoint = 'HEAD',
    [switch] $FailedInitializationConfirmed,
    [switch] $SessionStopped,
    [switch] $NoActiveWriter
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$git = (Get-Command git -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$utf8 = [Text.UTF8Encoding]::new($false)
$state = $null
$guard = $null
$candidate = $null

function Invoke-Git {
    param([string] $Directory, [string[]] $Arguments, [byte[]] $InputBytes, [string] $IndexPath)

    $info = [Diagnostics.ProcessStartInfo]::new()
    $info.FileName = $git
    $info.UseShellExecute = $false
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.RedirectStandardInput = $true
    foreach ($arg in @('--no-optional-locks', '-C', $Directory,
        '-c', 'core.longpaths=true', '-c', 'core.fsmonitor=false',
        '-c', 'core.sparseCheckout=false', '-c', 'core.sparseCheckoutCone=false',
        '-c', 'submodule.recurse=false', '-c', "core.hooksPath=$StatePath.no-hooks") + $Arguments) {
        $info.ArgumentList.Add($arg)
    }
    if ($IndexPath) { $info.Environment['GIT_INDEX_FILE'] = $IndexPath }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $info
    $buffer = [IO.MemoryStream]::new()
    try {
        if (-not $process.Start()) { throw 'Git did not start.' }
        $stdout = $process.StandardOutput.BaseStream.CopyToAsync($buffer)
        $stderr = $process.StandardError.ReadToEndAsync()
        if ($InputBytes) {
            $process.StandardInput.BaseStream.Write($InputBytes, 0, $InputBytes.Length)
        }
        $process.StandardInput.Close()
        $process.WaitForExit()
        [void] $stdout.GetAwaiter().GetResult()
        $errorText = $stderr.GetAwaiter().GetResult()
        if ($process.ExitCode -ne 0) {
            throw "Git $($Arguments -join ' ') exited $($process.ExitCode): $errorText"
        }
        $bytes = $buffer.ToArray()
        [pscustomobject]@{ Bytes = $bytes; Text = $utf8.GetString($bytes) }
    }
    finally {
        $buffer.Dispose()
        $process.Dispose()
    }
}

function Get-AbsolutePath {
    param([string] $Path)
    if (-not [IO.Path]::IsPathFullyQualified($Path)) { throw "Use an absolute path: '$Path'." }
    $full = [IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetFullPath($Path))
    $cursor = $full
    while ($cursor) {
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-Item -LiteralPath $cursor -Force
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Reparse-point paths are ambiguous: '$cursor'."
            }
        }
        $cursor = [IO.Path]::GetDirectoryName($cursor)
    }
    $full
}

function Test-Inside {
    param([string] $Child, [string] $Parent)
    $comparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    $Child.Equals($Parent, $comparison) -or
        $Child.StartsWith($Parent + [IO.Path]::DirectorySeparatorChar, $comparison)
}

function Save-State {
    $temporary = "$StatePath.$([Guid]::NewGuid().ToString('N')).tmp"
    try {
        [IO.File]::WriteAllText($temporary, ($state | ConvertTo-Json -Depth 5), $utf8)
        [IO.File]::Move($temporary, $StatePath, $true)
    }
    finally {
        if (Test-Path -LiteralPath $temporary) { [IO.File]::Delete($temporary) }
    }
}

function Open-StateGuard {
    $stream = [IO.File]::Open("$StatePath.lock", [IO.FileMode]::OpenOrCreate,
        [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    if ($stream.Length -ne 0) {
        $stream.Dispose()
        throw 'Nonempty state guard file is ambiguous.'
    }
    $stream
}

function Assert-Identity {
    $top = (Invoke-Git $state.worktree_path @('rev-parse', '--show-toplevel')).Text.Trim()
    if ((Get-AbsolutePath $top) -ne $state.worktree_path) { throw 'Worktree root differs from recorded path.' }
    $common = (Invoke-Git $state.worktree_path @('rev-parse', '--path-format=absolute', '--git-common-dir')).Text.Trim()
    if ((Get-AbsolutePath $common) -ne $state.common_dir) { throw 'Repository differs from recorded identity.' }
    $head = (Invoke-Git $state.worktree_path @('rev-parse', '--verify', 'HEAD')).Text.Trim()
    $branchRef = (Invoke-Git $state.worktree_path @('symbolic-ref', '-q', 'HEAD')).Text.Trim()
    if ($head -ne $state.commit -or $branchRef -cne "refs/heads/$($state.branch)") {
        throw 'Branch or HEAD differs from the intended commit.'
    }
    $records = (Invoke-Git $state.repo_path @('worktree', 'list', '--porcelain', '-z')).Text.Split("`0")
    if ("worktree $($state.worktree_path.Replace('\', '/'))" -notin $records -and
        "worktree $($state.worktree_path)" -notin $records) {
        throw 'Worktree is not registered in the source repository.'
    }
    $dir = (Invoke-Git $state.worktree_path @('rev-parse', '--absolute-git-dir')).Text.Trim()
    if ((Get-AbsolutePath $dir) -eq $state.common_dir) { throw 'Refusing to operate on the primary checkout.' }
    $dir
}

function Assert-Clean {
    param([string] $GitDirectory)
    foreach ($name in @('index.lock', 'HEAD.lock', 'locked')) {
        if (Test-Path -LiteralPath (Join-Path $GitDirectory $name)) {
            throw "Initialization or administrative lock exists: $name."
        }
    }
    $status = Invoke-Git $state.worktree_path @('status', '--porcelain=v1', '-z', '--untracked-files=all', '--ignore-submodules=none')
    if ($status.Bytes.Length -ne 0) { throw 'Worktree has missing files or unexpected tracked/untracked changes.' }
    $missing = Invoke-Git $state.worktree_path @('ls-files', '--deleted', '-z')
    if ($missing.Bytes.Length -ne 0) { throw 'Worktree has missing tracked files.' }
    $flags = (Invoke-Git $state.worktree_path @('ls-files', '-v', '-z')).Text.Split("`0", [StringSplitOptions]::RemoveEmptyEntries)
    if (@($flags | Where-Object { $_[0] -cne 'H' }).Count -ne 0) {
        throw 'Index flags or unmerged entries can hide changes.'
    }
    $indexTree = (Invoke-Git $state.worktree_path @('write-tree')).Text.Trim()
    $headTree = (Invoke-Git $state.worktree_path @('rev-parse', 'HEAD^{tree}')).Text.Trim()
    if ($indexTree -ne $headTree) { throw 'Index does not contain the complete HEAD tree.' }
}

function Assert-NoReparsePointParents {
    param([byte[]] $Paths)

    $start = 0
    for ($index = 0; $index -lt $Paths.Length; $index++) {
        if ($Paths[$index] -ne 0) { continue }
        if ($index -eq $start) { throw 'Git returned an empty deleted path.' }
        try {
            $relative = [Text.UTF8Encoding]::new($false, $true).GetString($Paths, $start, $index - $start)
        }
        catch {
            throw 'A deleted path is not valid UTF-8; refusing recovery.'
        }
        $start = $index + 1

        $segments = $relative.Split('/')
        if (@($segments | Where-Object { $_ -in @('', '.', '..') -or $_.Contains('\') }).Count -gt 0) {
            throw 'A deleted path is not a safe repository-relative path.'
        }
        $parent = $state.worktree_path
        for ($segmentIndex = 0; $segmentIndex -lt $segments.Count - 1; $segmentIndex++) {
            $parent = [IO.Path]::GetFullPath((Join-Path $parent $segments[$segmentIndex]))
            if (-not (Test-Inside $parent $state.worktree_path) -or $parent -eq $state.worktree_path) {
                throw 'A deleted path escapes the worktree.'
            }
            if (Test-Path -LiteralPath $parent) {
                $item = Get-Item -LiteralPath $parent -Force
                if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                    throw "Recovery found a reparse-point ancestor for deleted path '$relative'."
                }
                if (-not $item.PSIsContainer) {
                    throw "Recovery found a non-directory parent for deleted path '$relative'."
                }
            }
        }
    }
    if ($start -ne $Paths.Length) { throw 'Git returned an unterminated deleted path.' }
}

try {
    foreach ($name in @('GIT_DIR', 'GIT_WORK_TREE', 'GIT_COMMON_DIR', 'GIT_INDEX_FILE', 'GIT_OBJECT_DIRECTORY', 'GIT_ALTERNATE_OBJECT_DIRECTORIES')) {
        if ([Environment]::GetEnvironmentVariable($name)) { throw "Unset repository-routing environment variable $name first." }
    }
    $StatePath = Get-AbsolutePath $StatePath
    if (Test-Path -LiteralPath "$StatePath.no-hooks") { throw 'Reserved no-hooks path already exists.' }
    $stateParent = [IO.Path]::GetDirectoryName($StatePath)
    if (-not (Test-Path -LiteralPath $stateParent -PathType Container)) { throw 'State parent directory must already exist.' }
    if ($Action -eq 'Create') {
        if (Test-Path -LiteralPath $StatePath) { throw 'State already exists; use Verify or guarded Recover, not another Create.' }
        if (-not $RepoPath -or -not $WorktreePath -or -not $Branch) { throw 'Create requires RepoPath, WorktreePath, and Branch.' }
        $RepoPath = Get-AbsolutePath $RepoPath
        $RepoPath = Get-AbsolutePath (Invoke-Git $RepoPath @('rev-parse', '--show-toplevel')).Text.Trim()
        $WorktreePath = Get-AbsolutePath $WorktreePath
        if (Test-Path -LiteralPath $WorktreePath) { throw 'Target must not exist, even as an empty directory.' }
        if (-not (Test-Path -LiteralPath ([IO.Path]::GetDirectoryName($WorktreePath)) -PathType Container)) {
            throw 'Worktree parent directory must already exist.'
        }
        $records = (Invoke-Git $RepoPath @('worktree', 'list', '--porcelain', '-z')).Text.Split("`0")
        foreach ($record in $records) {
            if ($record.StartsWith('worktree ')) {
                $existing = Get-AbsolutePath $record.Substring(9)
                if ((Test-Inside $WorktreePath $existing) -or (Test-Inside $existing $WorktreePath)) {
                    throw 'Target overlaps an existing checkout or registered worktree.'
                }
                if (Test-Inside $StatePath $existing) { throw 'Keep state outside repository checkouts.' }
            }
        }
        if ((Test-Inside $StatePath $WorktreePath) -or (Test-Inside $WorktreePath $StatePath)) {
            throw 'State and worktree paths overlap.'
        }
        if ($Branch.StartsWith('-') -or (Invoke-Git $RepoPath @('check-ref-format', '--branch', $Branch)).Text.Trim() -cne $Branch) {
            throw 'Use a literal valid new branch name.'
        }
        $commit = (Invoke-Git $RepoPath @('rev-parse', '--verify', '--end-of-options', "$StartPoint^{commit}")).Text.Trim()
        $tree = (Invoke-Git $RepoPath @('ls-tree', '-r', $commit)).Text
        if ($tree -match '(?m)^160000 ') { throw 'Submodule checkouts are not supported by this initializer.' }
        $common = Get-AbsolutePath (Invoke-Git $RepoPath @('rev-parse', '--path-format=absolute', '--git-common-dir')).Text.Trim()
        $guard = Open-StateGuard
        if ((Test-Path -LiteralPath $StatePath) -or (Test-Path -LiteralPath $WorktreePath)) {
            throw 'State or target appeared during preflight; refusing creation.'
        }
        $state = [pscustomobject]@{
            schema_version = 1
            repo_path = $RepoPath
            common_dir = $common
            worktree_path = $WorktreePath
            branch = $Branch
            commit = $commit
            phase = 'initializing'
        }
        Save-State
        Invoke-Git $RepoPath @('worktree', 'add', '--quiet', '-b', $Branch, '--', $WorktreePath, $commit) | Out-Null
    }
    else {
        if (-not (Test-Path -LiteralPath $StatePath -PathType Leaf)) { throw 'Initialization state does not exist.' }
        $guard = Open-StateGuard
        $state = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
        if ($state.schema_version -ne 1 -or $state.phase -notin @('initializing', 'failed', 'ready')) {
            throw 'Unsupported initialization state.'
        }
        foreach ($name in @('repo_path', 'common_dir', 'worktree_path')) {
            if ((Get-AbsolutePath $state.$name) -ne $state.$name) { throw "Noncanonical state path: $name." }
        }
    }

    $gitDirectory = Assert-Identity
    if ($Action -eq 'Recover') {
        if ($state.phase -eq 'ready') { throw 'Refusing recovery of a previously ready worktree.' }
        if (-not ($FailedInitializationConfirmed -and $SessionStopped -and $NoActiveWriter)) {
            throw 'Recovery requires confirmed failed initialization, stopped session, and no active writer.'
        }
        foreach ($name in @('HEAD.lock', 'locked')) {
            if (Test-Path -LiteralPath (Join-Path $gitDirectory $name)) { throw "Ambiguous administrative lock: $name." }
        }
        $lock = Join-Path $gitDirectory 'index.lock'
        if (Test-Path -LiteralPath $lock) {
            $handle = [IO.File]::Open($lock, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
            try {
                if ($handle.Length -ne 0) { throw 'Nonempty index.lock is ambiguous; refusing recovery.' }
            }
            finally { $handle.Dispose() }
        }
        $candidate = "$StatePath.$([Guid]::NewGuid().ToString('N')).index"
        Invoke-Git $state.worktree_path @('read-tree', 'HEAD') -IndexPath $candidate | Out-Null
        $candidateDeleted = (Invoke-Git $state.worktree_path @('ls-files', '--deleted', '-z') -IndexPath $candidate).Bytes
        Assert-NoReparsePointParents $candidateDeleted
        $differences = (Invoke-Git $state.worktree_path @('diff', '--name-status', '-z', '--no-renames', '--no-ext-diff', '--no-textconv') -IndexPath $candidate).Text.Split("`0", [StringSplitOptions]::RemoveEmptyEntries)
        for ($i = 0; $i -lt $differences.Count; $i += 2) {
            if ($differences[$i] -ne 'D') { throw 'Surviving tracked files differ from HEAD; refusing recovery.' }
        }
        $extras = Invoke-Git $state.worktree_path @('ls-files', '--others', '-z') -IndexPath $candidate
        if ($extras.Bytes.Length -ne 0) { throw 'Unexpected files (including ignored files) make recovery ambiguous.' }
        $index = Join-Path $gitDirectory 'index'
        if (Test-Path -LiteralPath $index) {
            $staged = (Invoke-Git $state.worktree_path @('diff-index', '--cached', '--name-status', '-z', '--no-renames', 'HEAD')).Text.Split("`0", [StringSplitOptions]::RemoveEmptyEntries)
            for ($i = 0; $i -lt $staged.Count; $i += 2) {
                if ($staged[$i] -ne 'D') { throw 'Staged edits make recovery ambiguous.' }
            }
        }
        if (Test-Path -LiteralPath $lock) {
            $handle = [IO.File]::Open($lock, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::Delete)
            try {
                if ($handle.Length -ne 0) { throw 'Lock changed during inspection; refusing recovery.' }
                [IO.File]::Delete($lock)
            }
            finally { $handle.Dispose() }
        }
        Invoke-Git $state.worktree_path @('read-tree', 'HEAD') | Out-Null
        $deleted = (Invoke-Git $state.worktree_path @('ls-files', '--deleted', '-z')).Bytes
        if ($deleted.Length -gt 0) {
            Assert-NoReparsePointParents $deleted
            Invoke-Git $state.worktree_path @('checkout-index', '--stdin', '-z', '--quiet') -InputBytes $deleted | Out-Null
        }
    }
    Assert-Clean $gitDirectory
    $state.phase = 'ready'
    Save-State
    [pscustomobject]@{
        schema_version = 1; status = 'ready'; action = $Action; state_path = $StatePath
        worktree_path = $state.worktree_path; branch = $state.branch; commit = $state.commit
    } | ConvertTo-Json -Compress
}
catch {
    if ($null -ne $state -and $state.phase -eq 'initializing') {
        $state.phase = 'failed'
        Save-State
    }
    [pscustomobject]@{
        schema_version = 1; status = 'error'; action = $Action; state_path = $StatePath
        message = $_.Exception.Message
    } | ConvertTo-Json -Compress | Write-Output
    throw
}
finally {
    if ($candidate -and (Test-Path -LiteralPath $candidate)) { [IO.File]::Delete($candidate) }
    if ($null -ne $guard) { $guard.Dispose() }
}
