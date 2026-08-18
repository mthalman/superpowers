<#
.SYNOPSIS
    Focused tests for provider-neutral address-pr-comments support.

    Run:
        Invoke-Pester -Path tests/address-pr-comments/AddressPrComments.Tests.ps1 -Output Detailed
#>

BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:ModulePath = Join-Path $RepoRoot 'scripts' 'address-pr-comments-support.psm1'
    $script:Fixtures = Join-Path $PSScriptRoot 'fixtures'
    Import-Module $ModulePath -Force
}

Describe 'Resolve-AddressPrRemote' {
    It 'detects an Azure DevOps HTTPS remote with a username' {
        $result = Resolve-AddressPrRemote `
            -RemoteName 'upstream' `
            -RemoteUrl 'https://dnceng@dev.azure.com/dnceng/internal/_git/build-duty'

        $result.Provider | Should -Be 'azure-devops'
        $result.Organization | Should -Be 'dnceng'
        $result.Project | Should -Be 'internal'
        $result.Repository | Should -Be 'build-duty'
        $result.RemoteName | Should -Be 'upstream'
        $result.RemoteUrl | Should -Be 'https://dev.azure.com/dnceng/internal/_git/build-duty'
    }

    It 'preserves GitHub remote detection' {
        $result = Resolve-AddressPrRemote `
            -RemoteName 'fork' `
            -RemoteUrl 'git@github.com:mthalman/superpowers.git'

        $result.Provider | Should -Be 'github'
        $result.Organization | Should -Be 'mthalman'
        $result.Project | Should -BeNullOrEmpty
        $result.Repository | Should -Be 'superpowers'
    }

    It 'detects an Azure DevOps SSH remote' {
        $result = Resolve-AddressPrRemote `
            -RemoteName 'ado' `
            -RemoteUrl 'git@ssh.dev.azure.com:v3/dnceng/internal/build-duty'

        $result.Provider | Should -Be 'azure-devops'
        $result.Organization | Should -Be 'dnceng'
        $result.Project | Should -Be 'internal'
        $result.Repository | Should -Be 'build-duty'
    }

    It 'redacts credentials from an unsupported remote error' {
        $message = $null
        try {
            Resolve-AddressPrRemote `
                -RemoteName 'private' `
                -RemoteUrl 'https://user@tenant:secret@example.test/org/repo'
        }
        catch {
            $message = $_.Exception.Message
        }

        $message | Should -Not -BeNullOrEmpty
        $message | Should -Not -Match 'user@tenant:secret'
        $message | Should -Match 'https://example\.test/org/repo'
    }

    It 'detects Azure DevOps after redacting multiple at-signs from user information' {
        $result = Resolve-AddressPrRemote `
            -RemoteName 'ado' `
            -RemoteUrl 'https://user@tenant:secret@dev.azure.com/dnceng/internal/_git/build-duty'

        $result.Provider | Should -Be 'azure-devops'
        $result.RemoteUrl | Should -Be 'https://dev.azure.com/dnceng/internal/_git/build-duty'
    }
}

Describe 'Azure DevOps URLs' {
    BeforeAll {
        $script:AzureMetadata = [pscustomobject]@{
            provider      = 'azure-devops'
            organization  = 'dnceng'
            project       = 'internal'
            repository    = 'build-duty'
            repository_id = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
            pr_number     = 731
        }
    }

    It 'parses a pull request URL' {
        $result = ConvertFrom-AzureDevOpsPullRequestUrl `
            -Url 'https://dev.azure.com/dnceng/internal/_git/build-duty/pullrequest/731'

        $result.Organization | Should -Be 'dnceng'
        $result.Project | Should -Be 'internal'
        $result.Repository | Should -Be 'build-duty'
        $result.PullRequestId | Should -Be 731
    }

    It 'parses a legacy Azure DevOps pull request URL' {
        $result = ConvertFrom-AzureDevOpsPullRequestUrl `
            -Url 'https://dnceng.visualstudio.com/internal/_git/build-duty/pullrequest/731'

        $result.Organization | Should -Be 'dnceng'
        $result.Project | Should -Be 'internal'
        $result.Repository | Should -Be 'build-duty'
        $result.PullRequestId | Should -Be 731
    }

    It 'generates PR, thread, and commit URLs' {
        New-AddressPrPullRequestUrl -Metadata $AzureMetadata |
            Should -Be 'https://dev.azure.com/dnceng/internal/_git/build-duty/pullrequest/731'
        New-AddressPrThreadUrl -Metadata $AzureMetadata -ThreadId 41 |
            Should -Be 'https://dev.azure.com/dnceng/internal/_git/build-duty/pullrequest/731?discussionId=41'
        New-AddressPrCommitUrl -Metadata $AzureMetadata -CommitSha ('a' * 40) |
            Should -Be ('https://dev.azure.com/dnceng/internal/_git/build-duty/commit/' + ('a' * 40))
    }
}

Describe 'Azure DevOps thread normalization' {
    BeforeAll {
        $fixturePath = Join-Path $Fixtures 'azure-threads.json'
        $script:ThreadFixture = Get-Content -LiteralPath $fixturePath -Raw | ConvertFrom-Json
    }

    It 'treats active and pending as unresolved' {
        Test-AddressPrThreadUnresolved -Provider azure-devops -Thread ([pscustomobject]@{ status = 'active' }) |
            Should -BeTrue
        Test-AddressPrThreadUnresolved -Provider azure-devops -Thread ([pscustomobject]@{ status = 'pending' }) |
            Should -BeTrue
    }

    It 'filters resolved Azure DevOps statuses' {
        foreach ($status in 'fixed', 'wontFix', 'closed', 'byDesign') {
            Test-AddressPrThreadUnresolved -Provider azure-devops -Thread ([pscustomobject]@{ status = $status }) |
                Should -BeFalse
        }
    }

    It 'supports numeric Azure DevOps thread statuses' {
        Test-AddressPrThreadUnresolved -Provider azure-devops -Thread ([pscustomobject]@{ status = 1 }) |
            Should -BeTrue
        Test-AddressPrThreadUnresolved -Provider azure-devops -Thread ([pscustomobject]@{ status = 6 }) |
            Should -BeTrue
        Test-AddressPrThreadUnresolved -Provider azure-devops -Thread ([pscustomobject]@{ status = 2 }) |
            Should -BeFalse
    }

    It 'preserves GitHub unresolved-thread behavior' {
        Test-AddressPrThreadUnresolved `
            -Provider github `
            -Thread ([pscustomobject]@{ position = 4; isResolved = $false }) |
            Should -BeTrue
        Test-AddressPrThreadUnresolved `
            -Provider github `
            -Thread ([pscustomobject]@{ position = $null; isResolved = $false }) |
            Should -BeFalse
        Test-AddressPrThreadUnresolved `
            -Provider github `
            -Thread ([pscustomobject]@{ position = 4; isResolved = $true }) |
            Should -BeFalse
    }

    It 'rejects an unknown status instead of silently dropping a thread' {
        {
            Test-AddressPrThreadUnresolved `
                -Provider azure-devops `
                -Thread ([pscustomobject]@{ status = 'futureStatus' })
        } | Should -Throw '*Unknown Azure DevOps thread status*'
    }

    It 'ignores a status-less Azure DevOps system thread' {
        Test-AddressPrThreadUnresolved `
            -Provider azure-devops `
            -Thread $ThreadFixture.value[2] |
            Should -BeFalse
    }

    It 'preserves the complete conversation and file context' {
        $thread = ConvertFrom-AzureDevOpsThread -Thread $ThreadFixture.value[0]

        $thread.id | Should -Be '41'
        $thread.thread_id | Should -Be '41'
        $thread.root_comment_id | Should -Be '1'
        $thread.file | Should -Be 'src/Widget.cs'
        $thread.line | Should -Be 12
        @($thread.conversation).Count | Should -Be 2
        $thread.conversation[1].content | Should -Be 'I will update it.'
        $thread.latest_post_timestamp | Should -Be '2026-08-17T13:00:00.0000000Z'
    }

    It 'orders the conversation chronologically when the API response is unordered' {
        $source = $ThreadFixture.value[0]
        $unordered = [pscustomobject]@{
            id = $source.id
            status = $source.status
            publishedDate = $source.publishedDate
            threadContext = $source.threadContext
            comments = @($source.comments[1], $source.comments[0])
        }

        $thread = ConvertFrom-AzureDevOpsThread -Thread $unordered

        $thread.conversation[0].id | Should -Be '1'
        $thread.conversation[1].id | Should -Be '2'
    }

    It 'marks a remotely resolved thread as non-actionable' {
        $thread = ConvertFrom-AzureDevOpsThread -Thread $ThreadFixture.value[1]

        $thread.remote_unresolved | Should -BeFalse
        $thread.status | Should -Be 'completed'
    }

    It 'rejects an active thread without a root comment' {
        $thread = [pscustomobject]@{
            id = 44
            status = 'active'
            comments = @(
                [pscustomobject]@{
                    id = 2
                    parentCommentId = 1
                    commentType = 'text'
                    content = 'Reply without a root.'
                    publishedDate = '2026-08-17T13:00:00Z'
                }
            )
        }

        { ConvertFrom-AzureDevOpsThread -Thread $thread } |
            Should -Throw '*does not contain a root comment*'
    }

    It 'rejects an active thread without comments' {
        $thread = [pscustomobject]@{
            id = 45
            status = 'active'
            comments = @()
        }

        { ConvertFrom-AzureDevOpsThread -Thread $thread } |
            Should -Throw '*does not contain a root comment*'
    }
}

Describe 'Progress schema and resume' {
    BeforeAll {
        $script:GitHubMetadata = [pscustomobject]@{
            provider      = 'github'
            organization  = 'mthalman'
            project       = $null
            repository    = 'superpowers'
            repository_id = $null
            pr_number     = 123
            pr_url        = 'https://github.com/mthalman/superpowers/pull/123'
            branch        = 'feature/add-auth'
            source_branch = 'feature/add-auth'
            source_repository = 'superpowers'
            source_repository_owner = 'mthalman'
            remote_name   = 'fork'
            remote_url    = 'git@github.com:mthalman/superpowers.git'
        }
    }

    It 'upgrades legacy GitHub state without losing decisions or replies' {
        $legacyPath = Join-Path $Fixtures 'legacy-github-progress.json'
        $legacy = Get-Content -LiteralPath $legacyPath -Raw | ConvertFrom-Json

        $result = Merge-AddressPrProgress `
            -Existing $legacy `
            -Metadata $GitHubMetadata `
            -FreshComments @()

        $result.schema_version | Should -Be 2
        $result.provider | Should -Be 'github'
        $result.remote_name | Should -Be 'fork'
        $result.source_repository_owner | Should -Be 'mthalman'
        $result.comments[0].action | Should -Be 'auto_fixed'
        $result.comments[0].pending_replies | Should -Contain 'Fixed in abc123f'
        $result.comments[0].root_comment_id | Should -Be '123456789'
    }

    It 'matches legacy GitHub state by root comment ID instead of GraphQL thread ID' {
        $legacyPath = Join-Path $Fixtures 'legacy-github-progress.json'
        $legacy = Get-Content -LiteralPath $legacyPath -Raw | ConvertFrom-Json
        $fresh = [pscustomobject]@{
            id = 'PRRT_graphqlThread'
            thread_id = 'PRRT_graphqlThread'
            root_comment_id = '123456789'
            file = 'src/auth.ts'
            line = 43
            conversation = @()
            latest_post_timestamp = '2025-11-07T21:48:42Z'
            remote_unresolved = $true
        }

        $result = Merge-AddressPrProgress `
            -Existing $legacy `
            -Metadata $GitHubMetadata `
            -FreshComments @($fresh)

        @($result.comments).Count | Should -Be 1
        $result.comments[0].thread_id | Should -Be 'PRRT_graphqlThread'
        $result.comments[0].root_comment_id | Should -Be '123456789'
        $result.comments[0].action | Should -Be 'auto_fixed'
        $result.comments[0].pending_replies | Should -Contain 'Fixed in abc123f'
    }

    It 're-surfaces new activity while preserving its queued reply' {
        $existing = [pscustomobject]@{
            schema_version = 2
            provider = 'azure-devops'
            comments = @(
                [pscustomobject]@{
                    id = '41'
                    thread_id = '41'
                    root_comment_id = '1'
                    status = 'completed'
                    action = 'auto_fixed'
                    pending_replies = @('Fixed in [abc1234](https://example.test)')
                    last_post_timestamp = '2026-08-17T12:00:00Z'
                }
            )
        }
        $fresh = [pscustomobject]@{
            id = '41'
            thread_id = '41'
            root_comment_id = '1'
            file = 'src/Widget.cs'
            line = 12
            conversation = @()
            latest_post_timestamp = '2026-08-17T13:00:00Z'
        }

        $result = Merge-AddressPrProgress `
            -Existing $existing `
            -Metadata $AzureMetadata `
            -FreshComments @($fresh)

        $result.comments[0].status | Should -Be 'pending'
        $result.comments[0].action | Should -Be 'auto_fixed'
        $result.comments[0].pending_replies | Should -Contain 'Fixed in [abc1234](https://example.test)'
        $result.comments[0].last_post_timestamp | Should -Be '2026-08-17T13:00:00.0000000Z'
    }

    It 'closes a pending item resolved remotely when there is no new activity' {
        $existing = [pscustomobject]@{
            schema_version = 2
            provider = 'azure-devops'
            comments = @(
                [pscustomobject]@{
                    id = '42'
                    thread_id = '42'
                    root_comment_id = '1'
                    status = 'pending'
                    action = 'deferred'
                    pending_replies = @()
                    last_post_timestamp = '2026-08-16T10:00:00Z'
                }
            )
        }
        $fresh = ConvertFrom-AzureDevOpsThread -Thread $ThreadFixture.value[1]

        $result = Merge-AddressPrProgress `
            -Existing $existing `
            -Metadata $AzureMetadata `
            -FreshComments @($fresh)

        $result.comments[0].status | Should -Be 'completed'
        $result.comments[0].action | Should -Be 'deferred'
    }

    It 'uses the legacy path for GitHub and a provider-scoped path for Azure DevOps' {
        Get-AddressPrProgressRelativePath -Metadata $GitHubMetadata |
            Should -Be 'address-pr-comments/mthalman-superpowers/pr-123.json'
        Get-AddressPrProgressRelativePath -Metadata $AzureMetadata |
            Should -Be 'address-pr-comments/azure-devops/dnceng-internal-build-duty/pr-731.json'
    }
}

Describe 'Commit reply formatting' {
    It 'keeps the existing GitHub fixed reply format' {
        $metadata = [pscustomobject]@{ provider = 'github' }
        New-AddressPrFixedReply -Metadata $metadata -CommitSha 'abc1234' |
            Should -Be 'Fixed in abc1234'
    }

    It 'resolves an Azure DevOps short SHA and emits a Markdown commit link' {
        $fullSha = 'abcdef0123456789abcdef0123456789abcdef01'
        $resolver = { param($sha) $sha | Should -Be 'abc1234'; return $fullSha }

        New-AddressPrFixedReply `
            -Metadata $AzureMetadata `
            -CommitSha 'abc1234' `
            -ResolveCommitSha $resolver |
            Should -Be "Fixed in [abc1234](https://dev.azure.com/dnceng/internal/_git/build-duty/commit/$fullSha)"
    }
}

Describe 'Azure DevOps reply invocation' {
    It 'writes UTF-8 JSON without a BOM and preserves Markdown text' {
        $path = Join-Path $TestDrive 'reply.json'
        $content = 'Use `value` and preserve café.'

        Write-AzureDevOpsReplyPayload `
            -Path $path `
            -Content $content `
            -RootCommentId 17

        $bytes = [IO.File]::ReadAllBytes($path)
        @($bytes[0..2]) -join ',' | Should -Not -Be '239,187,191'
        $payload = [Text.Encoding]::UTF8.GetString($bytes) | ConvertFrom-Json
        $payload.content | Should -Be $content
        $payload.parentCommentId | Should -Be 17
        $payload.commentType | Should -Be 1
    }

    It 'builds the API 7.1 reply arguments' {
        $args = New-AzureDevOpsReplyInvokeArguments `
            -Metadata $AzureMetadata `
            -ThreadId 41 `
            -PayloadPath 'C:\temp\reply.json'

        $args -join ' ' | Should -Be (
            'devops invoke --organization https://dev.azure.com/dnceng ' +
            '--area git --resource pullRequestThreadComments ' +
            '--route-parameters project=internal repositoryId=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee ' +
            'pullRequestId=731 threadId=41 --api-version 7.1 --http-method POST ' +
            '--in-file C:\temp\reply.json --encoding utf-8 --output json --only-show-errors'
        )
    }

    It 'builds the API 7.1 thread-list arguments' {
        $args = New-AzureDevOpsThreadListInvokeArguments -Metadata $AzureMetadata

        $args -join ' ' | Should -Be (
            'devops invoke --organization https://dev.azure.com/dnceng ' +
            '--area git --resource pullRequestThreads ' +
            '--route-parameters project=internal repositoryId=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee ' +
            'pullRequestId=731 --api-version 7.1 --output json --only-show-errors'
        )
    }
}

Describe 'Invoke-AddressPrPendingReplies' {
    It 'persists immediately after each successful reply' {
        $progress = [pscustomobject]@{
            comments = @(
                [pscustomobject]@{
                    id = '41'
                    thread_id = '41'
                    root_comment_id = '1'
                    pending_replies = @('first', 'second')
                    last_post_timestamp = '2026-08-17T10:00:00Z'
                }
            )
        }
        $script:postIndex = 0
        $script:savedQueueCounts = @()
        $post = {
            param($comment, $reply)
            $script:postIndex++
            return [pscustomobject]@{
                id = 100 + $script:postIndex
                publishedDate = "2026-08-17T1$($script:postIndex):00:00Z"
            }
        }
        $save = {
            param($state)
            $script:savedQueueCounts += @($state.comments[0].pending_replies).Count
        }

        $result = Invoke-AddressPrPendingReplies `
            -Progress $progress `
            -PostReply $post `
            -SaveProgress $save

        $result.PostedCount | Should -Be 2
        @($result.Failures).Count | Should -Be 0
        $savedQueueCounts | Should -Be @(1, 0)
        @($progress.comments[0].pending_replies).Count | Should -Be 0
        $progress.comments[0].last_post_timestamp | Should -Be '2026-08-17T12:00:00.0000000Z'
    }

    It 'retains a failed reply while continuing with the next thread' {
        $progress = [pscustomobject]@{
            comments = @(
                [pscustomobject]@{
                    id = '41'
                    thread_id = '41'
                    root_comment_id = '1'
                    pending_replies = @('keep me')
                    last_post_timestamp = '2026-08-17T10:00:00Z'
                },
                [pscustomobject]@{
                    id = '42'
                    thread_id = '42'
                    root_comment_id = '1'
                    pending_replies = @('post me')
                    last_post_timestamp = '2026-08-17T10:00:00Z'
                }
            )
        }
        $post = {
            param($comment, $reply)
            if ($comment.thread_id -eq '41') { throw 'API unavailable' }
            return [pscustomobject]@{
                id = 201
                publishedDate = '2026-08-17T13:00:00Z'
            }
        }
        $script:saveCount = 0
        $save = { param($state) $script:saveCount++ }

        $result = Invoke-AddressPrPendingReplies `
            -Progress $progress `
            -PostReply $post `
            -SaveProgress $save

        $result.PostedCount | Should -Be 1
        @($result.Failures).Count | Should -Be 1
        $result.Failures[0].Reply | Should -Be 'keep me'
        $progress.comments[0].pending_replies | Should -Contain 'keep me'
        @($progress.comments[1].pending_replies).Count | Should -Be 0
        $saveCount | Should -Be 1
    }

    It 'retains a reply when the API response has no comment ID' {
        $progress = [pscustomobject]@{
            comments = @(
                [pscustomobject]@{
                    id = '41'
                    thread_id = '41'
                    root_comment_id = '1'
                    pending_replies = @('keep me')
                    last_post_timestamp = '2026-08-17T10:00:00Z'
                }
            )
        }
        $post = { param($comment, $reply) [pscustomobject]@{ publishedDate = '2026-08-17T13:00:00Z' } }
        $save = { param($state) throw 'must not save' }

        $result = Invoke-AddressPrPendingReplies `
            -Progress $progress `
            -PostReply $post `
            -SaveProgress $save

        $result.PostedCount | Should -Be 0
        @($result.Failures).Count | Should -Be 1
        $progress.comments[0].pending_replies | Should -Contain 'keep me'
    }
}
