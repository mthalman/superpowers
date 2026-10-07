[CmdletBinding()]
param(
    [string] $OutputDir,
    [ValidateRange(1, 20)] [int] $Runs = 3,
    [switch] $SkipUplift,
    [switch] $DryRun,
    [switch] $Publish,
    [string] $Remote,
    [string] $AutomationSessionUrl
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$env:VALLY_TELEMETRY_OPTOUT = '1'

function Invoke-Checked {
    param(
        [Parameter(Mandatory)] [scriptblock] $Command,
        [Parameter(Mandatory)] [string] $Failure
    )
    & $Command
    if ($LASTEXITCODE -ne 0) { throw $Failure }
}

function Resolve-PublicationRemote {
    param([string] $Root, [string] $RequestedRemote)

    if ($RequestedRemote) { return $RequestedRemote }
    $upstream = & git -C $Root rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>$null
    if ($LASTEXITCODE -eq 0 -and $upstream -match '^([^/]+)/') {
        return $Matches[1]
    }
    $remotes = @(& git -C $Root remote)
    if ($remotes.Count -eq 1) { return $remotes[0] }
    throw 'Specify -Remote because the repository has no unambiguous upstream remote.'
}

$repoRoot = (& git rev-parse --show-toplevel).Trim()
$toolDir = Join-Path $repoRoot 'evals\_vally'
$node = (Get-Command node -ErrorAction Stop).Source
$nodeVersion = (& $node --version).TrimStart('v')
if ([Version] $nodeVersion -lt [Version] '22.12.0') {
    throw "Vally requires Node.js 22.12.0 or newer; found $nodeVersion."
}
if ($Publish -and $SkipUplift) {
    throw 'Published canonical nightly runs must include the uplift experiment.'
}
if ($Publish -and (& git -C $repoRoot status --porcelain)) {
    throw 'Published nightly runs require a clean source worktree so the source SHA fully describes the evaluated code.'
}

$sourceSha = (& git -C $repoRoot rev-parse HEAD).Trim()
$shortSha = $sourceSha.Substring(0, 7)
$timestamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmssfff')
$runId = "$timestamp-$shortSha"
$publicationBranch = "vally-history/$runId"

$vally = Join-Path $toolDir 'node_modules\@microsoft\vally-cli\dist\index.js'
if (-not (Test-Path $vally -PathType Leaf)) {
    Invoke-Checked {
        npm ci --prefix $toolDir --no-audit --no-fund
    } 'npm ci failed for the Vally toolchain.'
}

$tsc = Join-Path $toolDir 'node_modules\typescript\bin\tsc'
Invoke-Checked {
    & $node $tsc --project (Join-Path $toolDir 'tsconfig.json')
} 'The Vally TypeScript plugins failed to build.'

$grader = (Resolve-Path (Join-Path $toolDir 'dist\graders\finding-match.js')).Path.Replace('\', '/')
$detection = (Resolve-Path (Join-Path $toolDir 'dist\reporters\detection.js')).Path.Replace('\', '/')
$pagesReporter = (Resolve-Path (Join-Path $toolDir 'dist\reporters\pages-history.js')).Path.Replace('\', '/')
$publicationTool = Join-Path $toolDir 'dist\tools\build-nightly-publication.js'
$evalSpecs = @(Get-ChildItem (Join-Path $repoRoot 'evals') -Filter eval.yaml -Recurse)

$remoteUrl = $null
$repository = 'mthalman/superpowers'
if ($Publish) {
    $Remote = Resolve-PublicationRemote -Root $repoRoot -RequestedRemote $Remote
    $remoteUrl = (& git -C $repoRoot remote get-url $Remote).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $remoteUrl) {
        throw "Could not resolve Git remote '$Remote'."
    }
    if ($remoteUrl -match 'github\.com[:/](.+?)(?:\.git)?$') {
        $repository = $Matches[1]
    }
    Invoke-Checked {
        gh auth status
    } 'The GitHub CLI is not authenticated. Run gh auth login before publishing.'
    Invoke-Checked {
        & git ls-remote --exit-code --heads $remoteUrl gh-pages
    } "The '$Remote' remote does not contain gh-pages. Initialize that branch before publishing."
}

if ($DryRun) {
    foreach ($evalSpec in $evalSpecs) {
        Invoke-Checked {
            & $node $vally lint --eval-spec $evalSpec.FullName --grader-plugin $grader --strict
        } "Vally lint failed for '$($evalSpec.FullName)'."
    }
    Invoke-Checked {
        & $node $vally experiment run `
            (Join-Path $repoRoot 'evals\experiments\skill-uplift.experiment.yaml') `
            --param "RUNS=$Runs" `
            --dry-run
    } 'The skill uplift experiment failed to resolve.'
    if ($Publish) {
        Write-Host "Publication prerequisites are valid for $Remote/gh-pages."
    }
    return
}

if (-not $OutputDir) {
    $OutputDir = Join-Path $repoRoot "vally-results\nightly-$runId"
}
$OutputDir = [IO.Path]::GetFullPath($OutputDir)
$outputRelative = [IO.Path]::GetRelativePath($repoRoot, $OutputDir).Replace('\', '/')
if ($Publish -and ($outputRelative -eq '..' -or $outputRelative.StartsWith('../'))) {
    throw 'Published runs require -OutputDir to be inside the repository so the PR can record a repository-relative diagnostics path.'
}
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
$pagesDir = Join-Path $OutputDir 'pages'

if ($Publish) {
    Invoke-Checked {
        & git clone --quiet --single-branch --branch gh-pages $remoteUrl $pagesDir
    } "Failed to clone gh-pages from remote '$Remote'."
    Invoke-Checked {
        & git -C $pagesDir switch -c $publicationBranch
    } "Failed to create publication branch '$publicationBranch'."
} else {
    New-Item -ItemType Directory -Path $pagesDir -Force | Out-Null
}

$env:VALLY_PAGES_DIR = $pagesDir
$env:VALLY_RUN_ID = $runId
$env:VALLY_RUN_KIND = 'nightly'
$env:VALLY_COMMIT = $sourceSha
$env:VALLY_REPOSITORY = $repository

foreach ($evalSpec in $evalSpecs) {
    $skill = Split-Path $evalSpec.DirectoryName -Leaf
    Write-Host "Running $skill ($Runs trials per stimulus)..."
    Invoke-Checked {
        & $node $vally eval `
            --eval-spec $evalSpec.FullName `
            --suite nightly `
            --runs $Runs `
            --output-dir (Join-Path $OutputDir $skill) `
            --grader-plugin $grader `
            --reporter-plugin $pagesReporter `
            --reporter-plugin $detection
    } "Vally evaluation failed operationally for '$skill'. Partial data was retained locally but will not be published."
}

$comparisonFile = Join-Path $OutputDir 'uplift-comparisons.jsonl'
if (-not $SkipUplift) {
    $upliftDir = Join-Path $OutputDir 'uplift'
    Invoke-Checked {
        & $node $vally experiment run `
            (Join-Path $repoRoot 'evals\experiments\skill-uplift.experiment.yaml') `
            --param "RUNS=$Runs" `
            --output-dir $upliftDir
    } 'The skill uplift experiment failed operationally. Partial data was retained locally but will not be published.'

    $experiment = Get-ChildItem $upliftDir -Directory |
        Sort-Object LastWriteTimeUtc -Descending |
        Select-Object -First 1
    if (-not $experiment) {
        throw 'Vally did not create an uplift experiment output directory.'
    }
    Invoke-Checked {
        & $node $vally compare $experiment.FullName --output $comparisonFile
    } 'The skill uplift comparison was incomplete. Partial data was retained locally but will not be published.'
}

$store = Join-Path $OutputDir 'eval-history.sqlite'
Get-ChildItem $OutputDir -Filter results.jsonl -Recurse | ForEach-Object {
    Invoke-Checked {
        & $node $vally ingest $_.DirectoryName --store $store
    } "Vally ingestion failed for '$($_.DirectoryName)'."
}

if (-not $SkipUplift) {
    $publicationArguments = @(
        $publicationTool,
        '--pages-dir', $pagesDir,
        '--comparison-file', $comparisonFile,
        '--run-id', $runId,
        '--source-sha', $sourceSha,
        '--publication-branch', $publicationBranch,
        '--runs', [string] $Runs,
        '--repository', $repository,
        '--repo-root', $repoRoot,
        '--output-relative', $outputRelative
    )
    if ($AutomationSessionUrl) {
        $publicationArguments += @('--automation-session-url', $AutomationSessionUrl)
    }
    Invoke-Checked {
        & $node @publicationArguments
    } 'Nightly publication data failed schema validation. Nothing was published.'
}

& (Join-Path $repoRoot 'scripts\Build-VallyDashboardManifest.ps1') `
    -PagesDir $pagesDir `
    -Repository $repository
& (Join-Path $repoRoot 'scripts\sync-dashboard.ps1') `
    -SourceDir (Join-Path $repoRoot 'dashboard') `
    -PagesDir $pagesDir

if ($Publish) {
    $userName = (& git -C $repoRoot config user.name)
    $userEmail = (& git -C $repoRoot config user.email)
    if (-not $userName) { $userName = 'Vally Automation' }
    if (-not $userEmail) { $userEmail = 'vally-automation@users.noreply.github.com' }
    & git -C $pagesDir config user.name $userName
    & git -C $pagesDir config user.email $userEmail
    & git -C $pagesDir add --all
    & git -C $pagesDir diff --cached --quiet
    $diffExitCode = $LASTEXITCODE
    if ($diffExitCode -gt 1) {
        throw 'Failed to inspect the generated Vally dashboard changes.'
    }
    if ($diffExitCode -eq 0) {
        throw 'The nightly run produced no publishable dashboard changes.'
    }

    Invoke-Checked {
        & git -C $pagesDir commit `
            -m "Publish Vally nightly $runId" `
            -m "Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>"
    } 'Failed to commit the nightly Vally dashboard data.'

    try {
        Invoke-Checked {
            & git -C $pagesDir push --set-upstream origin $publicationBranch
        } "Failed to push publication branch '$publicationBranch'."

        $title = "Vally nightly $($timestamp.Substring(0, 8)) $shortSha"
        $bodyPath = Join-Path $OutputDir 'nightly-pr-body.md'
        $prUrl = & gh pr create `
            --repo $repository `
            --base gh-pages `
            --head $publicationBranch `
            --title $title `
            --body-file $bodyPath
        if ($LASTEXITCODE -ne 0 -or -not $prUrl) {
            throw 'GitHub CLI failed to create the nightly history pull request.'
        }
        Write-Host "Nightly history PR: $($prUrl.Trim())"
    }
    catch {
        Write-Error $_
        Write-Host 'Publication branch and local output were preserved.'
        Write-Host "Manual push: git -C `"$pagesDir`" push --set-upstream origin $publicationBranch"
        Write-Host "Manual PR: gh pr create --repo $repository --base gh-pages --head $publicationBranch --title `"Vally nightly $($timestamp.Substring(0, 8)) $shortSha`" --body-file `"$OutputDir\nightly-pr-body.md`""
        throw
    }
}

Write-Host "Nightly Vally results: $OutputDir"
Write-Host "Open them with: .\scripts\Start-EvalDashboard.ps1 -ResultsDir `"$OutputDir`""
if (-not $Publish) {
    Write-Host 'Dashboard data was generated locally. Use -Publish to push a publication branch and create a PR targeting gh-pages.'
}
