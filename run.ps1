# Start the agents container with the current directory mounted at /workspace.
# PowerShell version of run.sh, for Windows.
#
#   .\run.ps1                interactive bash shell (claude, codex, opencode, uv, gh, vim, emacs)
#   .\run.ps1 claude         run one command directly, e.g. claude, codex, opencode
#   .\run.ps1 code           VS Code in the browser at http://localhost:8080
#   .\run.ps1 build          build the image locally instead of pulling it
#
# API keys and endpoint settings are passed through from your host environment if set;
# agent config and login state persist in named volumes.
#
# Uses whichever of podman or docker is running (podman first). Force one with $env:CONTAINER_ENGINE = "docker".
begin {
$Image = if ($env:IMAGE) { $env:IMAGE } else { 'ghcr.io/autonomous-scientific-agents/agentic-coding:latest' }
$Port = if ($env:PORT) { $env:PORT } else { '8080' }

$Engine = $env:CONTAINER_ENGINE
if (-not $Engine) {
    # Prefer an engine that is actually running (podman first), else the first one installed,
    # so a docker CLI left pointing at a stopped Docker Desktop doesn't win.
    $Installed = @('podman', 'docker') | Where-Object { Get-Command $_ -ErrorAction SilentlyContinue }
    foreach ($e in $Installed) {
        & $e info *> $null
        if ($LASTEXITCODE -eq 0) { $Engine = $e; break }
    }
    if (-not $Engine) { $Engine = $Installed | Select-Object -First 1 }
    if (-not $Engine) {
        Write-Host 'run.ps1: neither podman nor docker was found on your PATH' -ForegroundColor Red
        exit 1
    }
}

$Command = if ($args.Count -gt 0) { $args[0] } else { '' }
$Rest = @($args | Select-Object -Skip 1)

if ($Command -eq 'build') {
    & $Engine build -t $Image $PSScriptRoot
    exit $LASTEXITCODE
}

$RunArgs = @(
    '--rm', '-i',
    '-v', "$($PWD.Path):/workspace",
    '-v', 'ai-agents-claude:/home/dev/.claude',
    '-v', 'ai-agents-codex:/home/dev/.codex',
    '-v', 'ai-agents-opencode:/home/dev/.local/share/opencode',
    '-v', 'ai-agents-opencode-config:/home/dev/.config/opencode',
    '-v', 'ai-agents-code-server:/home/dev/.local/share/code-server',
    '-v', 'ai-agents-gh:/home/dev/.config/gh',
    '-v', 'ai-agents-globus:/home/dev/.globus'
)
# PowerShell pipelines do not necessarily redirect the host's console handles.
$PipelineInput = $MyInvocation.ExpectingInput
# With pwsh -File, the host adds Out-Default; an empty invocation line identifies that case.
$PipelineOutput = $MyInvocation.Line -and ($MyInvocation.PipelinePosition -lt $MyInvocation.PipelineLength)
# > / >> redirections and captures such as $x = .\run.ps1 ... or (.\run.ps1 ...) also leave the
# host console handles unchanged. Parse the invocation rather than matching characters in arguments.
function Test-OutputRedirected($Command) {
    @($Command.Redirections | Where-Object {
        $_ -is [System.Management.Automation.Language.FileRedirectionAst] -and $_.FromStream -in @('Output', 'All')
    }).Count -gt 0
}
function Find-InvocationCommand($Text, $Column) {
    $Tokens = $null
    $ParseErrors = $null
    $Ast = [System.Management.Automation.Language.Parser]::ParseInput($Text, [ref]$Tokens, [ref]$ParseErrors)
    $Ast.Find({
        param($Node)
        $Node -is [System.Management.Automation.Language.CommandAst] -and
            $Node.Extent.StartLineNumber -eq 1 -and $Node.Extent.StartColumnNumber -eq $Column
    }, $true)
}
function Test-OutputCaptured($Command) {
    # Walk out from this command until its output reaches the host or something consumes it.
    $Node = $Command
    while ($Node.Parent) {
        $Parent = $Node.Parent
        if ($Node -is [System.Management.Automation.Language.CommandBaseAst] -and (Test-OutputRedirected $Node)) {
            return $true
        }
        if ($Parent -is [System.Management.Automation.Language.PipelineAst] -and
            $Parent.PipelineElements[-1] -ne $Node) { return $true }
        if ($Node -is [System.Management.Automation.Language.PipelineAst] -and
            $Parent -isnot [System.Management.Automation.Language.NamedBlockAst] -and
            $Parent -isnot [System.Management.Automation.Language.StatementBlockAst]) { return $true }
        if ($Node -is [System.Management.Automation.Language.StatementBlockAst] -and
            ($Parent -is [System.Management.Automation.Language.SubExpressionAst] -or
             $Parent -is [System.Management.Automation.Language.ArrayExpressionAst])) { return $true }
        if ($Node -is [System.Management.Automation.Language.ScriptBlockExpressionAst]) {
            # Follow only script blocks invoked in place with & { } or . { }.
            if ($Parent -isnot [System.Management.Automation.Language.CommandAst] -or
                $Parent.CommandElements[0] -ne $Node -or
                $Parent.InvocationOperator -notin @('Ampersand', 'Dot')) { return $false }
        }
        $Node = $Parent
    }
    $false
}
if ($MyInvocation.Line) {
    $InvocationCommand = Find-InvocationCommand $MyInvocation.Line $MyInvocation.OffsetInLine
    if ($InvocationCommand -and (Test-OutputCaptured $InvocationCommand)) { $PipelineOutput = $true }
}
# PowerShell 7.4+ also gives the whole statement, including redirections on continuation lines.
if ($MyInvocation.Statement) {
    $InvocationCommand = Find-InvocationCommand $MyInvocation.Statement 1
    if ($InvocationCommand -and (Test-OutputRedirected $InvocationCommand)) { $PipelineOutput = $true }
}
if (-not $PipelineInput -and -not $PipelineOutput -and
    -not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected) {
    $RunArgs += '-t'
}

# Commit as you: use your git name and email unless GIT_AUTHOR_*/GIT_COMMITTER_* are already set.
if (Get-Command git -ErrorAction SilentlyContinue) {
    $GitName = "$(git config user.name 2>$null)".Trim()
    $GitEmail = "$(git config user.email 2>$null)".Trim()
    if ($GitName) {
        if (-not $env:GIT_AUTHOR_NAME) { $env:GIT_AUTHOR_NAME = $GitName }
        if (-not $env:GIT_COMMITTER_NAME) { $env:GIT_COMMITTER_NAME = $GitName }
    }
    if ($GitEmail) {
        if (-not $env:GIT_AUTHOR_EMAIL) { $env:GIT_AUTHOR_EMAIL = $GitEmail }
        if (-not $env:GIT_COMMITTER_EMAIL) { $env:GIT_COMMITTER_EMAIL = $GitEmail }
    }
}

# ALCF tokens last 48 hours. If you have run `alcf-tokens login inference` on this machine, get a fresh one.
if (Get-Command alcf-tokens -ErrorAction SilentlyContinue) {
    $Token = "$(alcf-tokens get-token inference 2>$null)".Trim()
    if ($LASTEXITCODE -eq 0 -and $Token) { $env:ALCF_AI_TOKEN = $Token }
}

# Pass model-access settings from your shell into the container when they are set. `-e NAME` copies
# the value without putting it on the command line. AMSC_* holds the MAG token, ALCF_* the ALCF token.
# GH_TOKEN is passed only if you set it yourself, e.g. $env:GH_TOKEN = gh auth token
$Passthrough = @(
    'ANTHROPIC_API_KEY', 'ANTHROPIC_AUTH_TOKEN', 'ANTHROPIC_BASE_URL', 'ANTHROPIC_CUSTOM_HEADERS',
    'ANTHROPIC_MODEL', 'ANTHROPIC_DEFAULT_OPUS_MODEL', 'ANTHROPIC_DEFAULT_SONNET_MODEL', 'ANTHROPIC_DEFAULT_HAIKU_MODEL',
    'CLAUDE_CODE_SUBAGENT_MODEL', 'CLAUDE_CODE_MAX_OUTPUT_TOKENS', 'CLAUDE_CODE_AUTO_COMPACT_WINDOW',
    'CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS', 'CLAUDE_CODE_NO_FLICKER',
    'DISABLE_TELEMETRY', 'DISABLE_NON_ESSENTIAL_MODEL_CALLS',
    'OPENAI_API_KEY', 'OPENAI_BASE_URL', 'OPENROUTER_API_KEY',
    'GH_TOKEN',
    'GIT_AUTHOR_NAME', 'GIT_AUTHOR_EMAIL', 'GIT_COMMITTER_NAME', 'GIT_COMMITTER_EMAIL'
) + @(Get-ChildItem env: | Where-Object Name -match '^(AMSC|ALCF)_' | ForEach-Object Name)
foreach ($Name in $Passthrough) {
    if ([Environment]::GetEnvironmentVariable($Name)) { $RunArgs += '-e', $Name }
}

# Rootless Podman: map your user to dev (UID/GID 1000 in the image) so it can edit the project.
# Docker Desktop already takes care of this.
if ("$(& $Engine --version 2>$null)" -like 'podman*' -and
    "$(& $Engine info -f '{{.Host.Security.Rootless}}' 2>$null)" -eq 'true') {
    $RunArgs += '--userns=keep-id:uid=1000,gid=1000'
}

$ContainerArgs = @($args)
if ($Command -eq 'code') {
    # Bound to localhost on the host only, so no password is needed.
    $RunArgs += '-p', "127.0.0.1:${Port}:8080"
    $ContainerArgs = @('code-server', '--bind-addr', '0.0.0.0:8080', '--auth', 'none', '--disable-telemetry') +
        $Rest + @('/workspace')
}

if ($PipelineInput) {
    # Keep one native process alive across pipeline records instead of collecting $input.
    $EnginePipeline = { & $Engine run @RunArgs $Image @ContainerArgs }.GetSteppablePipeline()
    $EnginePipeline.Begin($true)
} else {
    & $Engine run @RunArgs $Image @ContainerArgs
    exit $LASTEXITCODE
}
}

process {
    if ($PipelineInput) { $EnginePipeline.Process($_) }
}

end {
    if ($PipelineInput) { $EnginePipeline.End() }
    exit $LASTEXITCODE
}
