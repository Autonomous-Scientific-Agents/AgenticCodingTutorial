#!/usr/bin/env bash
# Start the agents container with the current directory mounted at /workspace.
#
#   ./run.sh                 interactive bash shell (claude, codex, opencode, uv, vim, emacs)
#   ./run.sh claude          run one command directly, e.g. claude, codex, opencode
#   ./run.sh code            VS Code in the browser at http://localhost:8080
#   ./run.sh build           build the image locally instead of pulling it
#
# API keys and endpoint settings are passed through from your host environment if set;
# agent config and login state persist in named Docker volumes.
set -euo pipefail

IMAGE="${IMAGE:-ghcr.io/autonomous-scientific-agents/agentic-coding:latest}"
PORT="${PORT:-8080}"

if [[ "${1:-}" == "build" ]]; then
  exec docker build -t "$IMAGE" "$(cd "$(dirname "$0")" && pwd)"
fi

args=(
  --rm -it
  -v "$PWD":/workspace
  -v ai-agents-claude:/home/dev/.claude
  -v ai-agents-codex:/home/dev/.codex
  -v ai-agents-opencode:/home/dev/.local/share/opencode
  -v ai-agents-code-server:/home/dev/.local/share/code-server
  -e ANTHROPIC_API_KEY -e ANTHROPIC_AUTH_TOKEN -e ANTHROPIC_BASE_URL
  -e OPENAI_API_KEY -e OPENAI_BASE_URL
  -e OPENROUTER_API_KEY
)

if [[ "${1:-}" == "code" ]]; then
  shift
  # Bound to localhost on the host only, so no password is needed.
  exec docker run "${args[@]}" -p "127.0.0.1:${PORT}:8080" "$IMAGE" \
    code-server --bind-addr 0.0.0.0:8080 --auth none --disable-telemetry "$@" /workspace
fi

exec docker run "${args[@]}" "$IMAGE" "$@"
