#!/usr/bin/env bash
# Start the agents container with the current directory mounted at /workspace.
#
#   ./run.sh                 interactive bash shell (claude, codex, opencode, uv, gh, vim, emacs)
#   ./run.sh claude          run one command directly, e.g. claude, codex, opencode
#   ./run.sh code            VS Code in the browser at http://localhost:8080
#   ./run.sh build           build the image locally instead of pulling it
#
# API keys and endpoint settings are passed through from your host environment if set;
# agent config and login state persist in named volumes.
#
# Uses docker if it is installed, otherwise podman. Force one with CONTAINER_ENGINE=podman.
set -euo pipefail

IMAGE="${IMAGE:-ghcr.io/autonomous-scientific-agents/agentic-coding:latest}"
PORT="${PORT:-8080}"

ENGINE="${CONTAINER_ENGINE:-}"
if [[ -z "$ENGINE" ]]; then
  if command -v docker >/dev/null 2>&1; then
    ENGINE=docker
  elif command -v podman >/dev/null 2>&1; then
    ENGINE=podman
  else
    echo "run.sh: neither docker nor podman was found on your PATH" >&2
    exit 1
  fi
fi

if [[ "${1:-}" == "build" ]]; then
  exec "$ENGINE" build -t "$IMAGE" "$(cd "$(dirname "$0")" && pwd)"
fi

args=(
  --rm -it
  -v "$PWD":/workspace
  -v ai-agents-claude:/home/dev/.claude
  -v ai-agents-codex:/home/dev/.codex
  -v ai-agents-opencode:/home/dev/.local/share/opencode
  -v ai-agents-opencode-config:/home/dev/.config/opencode
  -v ai-agents-code-server:/home/dev/.local/share/code-server
  -e ANTHROPIC_API_KEY -e ANTHROPIC_AUTH_TOKEN -e ANTHROPIC_BASE_URL
  -e OPENAI_API_KEY -e OPENAI_BASE_URL
  -e OPENROUTER_API_KEY
)

# Make dev (UID/GID 1000 in the image) own the mounted project, so the agent can edit it and
# the files stay yours on the host. Docker Desktop (macOS, Windows) already takes care of this.
if [[ "$("$ENGINE" --version 2>/dev/null)" == podman* ]] \
    && [[ "$("$ENGINE" info -f '{{.Host.Security.Rootless}}' 2>/dev/null)" == true ]]; then
  args+=(--userns=keep-id:uid=1000,gid=1000)
elif [[ "$(uname -s)" == Linux && "$(id -u)" != 0 && "$(id -u):$(id -g)" != 1000:1000 ]]; then
  # entrypoint.sh renumbers dev to this UID/GID, then drops from root to dev.
  # An image from before entrypoint.sh existed would just stay root, so refuse to use it.
  if "$ENGINE" image inspect "$IMAGE" >/dev/null 2>&1 \
      && [[ "$("$ENGINE" image inspect -f '{{.Config.Entrypoint}}' "$IMAGE")" != *entrypoint.sh* ]]; then
    echo "run.sh: your copy of $IMAGE is out of date; update it with: $ENGINE pull $IMAGE" >&2
    exit 1
  fi
  args+=(--user 0:0 -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)")
fi

if [[ "${1:-}" == "code" ]]; then
  shift
  # Bound to localhost on the host only, so no password is needed.
  exec "$ENGINE" run "${args[@]}" -p "127.0.0.1:${PORT}:8080" "$IMAGE" \
    code-server --bind-addr 0.0.0.0:8080 --auth none --disable-telemetry "$@" /workspace
fi

exec "$ENGINE" run "${args[@]}" "$IMAGE" "$@"
