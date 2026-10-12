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
# Uses docker if it is installed, otherwise podman. Force one with $env:CONTAINER_ENGINE = "podman".
$Image = if ($env:IMAGE) { $env:IMAGE } else { 'ghcr.io/autonomous-scientific-agents/agentic-coding:latest' }
$Port = if ($env:PORT) { $env:PORT } else { '8080' }

$Engine = $env:CONTAINER_ENGINE
if (-not $Engine) {
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        $Engine = 'docker'
    } elseif (Get-Command podman -ErrorAction SilentlyContinue) {
        $Engine = 'podman'
    } else {
        Write-Host 'run.ps1: neither docker nor podman was found on your PATH' -ForegroundColor Red
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
    '-e', 'ANTHROPIC_API_KEY', '-e', 'ANTHROPIC_AUTH_TOKEN', '-e', 'ANTHROPIC_BASE_URL',
    '-e', 'OPENAI_API_KEY', '-e', 'OPENAI_BASE_URL',
    '-e', 'OPENROUTER_API_KEY'
)

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
