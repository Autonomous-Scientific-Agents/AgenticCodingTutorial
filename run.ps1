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
    '--rm', '-it',
    '-v', "$($PWD.Path):/workspace",
    '-v', 'ai-agents-claude:/home/dev/.claude',
    '-v', 'ai-agents-codex:/home/dev/.codex',
    '-v', 'ai-agents-opencode:/home/dev/.local/share/opencode',
    '-v', 'ai-agents-opencode-config:/home/dev/.config/opencode',
    '-v', 'ai-agents-code-server:/home/dev/.local/share/code-server',
    '-v', 'ai-agents-gh:/home/dev/.config/gh'
)

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

if ($Command -eq 'code') {
    # Bound to localhost on the host only, so no password is needed.
    & $Engine run @RunArgs -p "127.0.0.1:${Port}:8080" $Image `
        code-server --bind-addr 0.0.0.0:8080 --auth none --disable-telemetry @Rest /workspace
    exit $LASTEXITCODE
}

& $Engine run @RunArgs $Image @args
exit $LASTEXITCODE
