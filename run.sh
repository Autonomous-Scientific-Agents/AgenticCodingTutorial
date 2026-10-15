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
# Uses whichever of podman or docker is running (podman first). Force one with CONTAINER_ENGINE=docker.
set -euo pipefail

IMAGE="${IMAGE:-ghcr.io/autonomous-scientific-agents/agentic-coding:latest}"
PORT="${PORT:-8080}"

ENGINE="${CONTAINER_ENGINE:-}"
if [[ -z "$ENGINE" ]]; then
  # Prefer an engine that is actually running (podman first), else the first one installed,
  # so a docker CLI left pointing at a stopped Docker Desktop or Colima doesn't win.
  for e in podman docker; do
    if command -v "$e" >/dev/null 2>&1 && "$e" info >/dev/null 2>&1; then
      ENGINE=$e
      break
    fi
  done
  if [[ -z "$ENGINE" ]]; then
    for e in podman docker; do
      command -v "$e" >/dev/null 2>&1 && { ENGINE=$e; break; }
    done
  fi
  if [[ -z "$ENGINE" ]]; then
    echo "run.sh: neither podman nor docker was found on your PATH" >&2
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
  -v ai-agents-gh:/home/dev/.config/gh
  -v ai-agents-globus:/home/dev/.globus
)

# Commit as you: use your git name and email unless GIT_AUTHOR_*/GIT_COMMITTER_* are already set.
if command -v git >/dev/null 2>&1; then
  name="$(git config user.name 2>/dev/null || true)"
  email="$(git config user.email 2>/dev/null || true)"
  [[ -n "$name" ]] && export GIT_AUTHOR_NAME="${GIT_AUTHOR_NAME:-$name}" GIT_COMMITTER_NAME="${GIT_COMMITTER_NAME:-$name}"
  [[ -n "$email" ]] && export GIT_AUTHOR_EMAIL="${GIT_AUTHOR_EMAIL:-$email}" GIT_COMMITTER_EMAIL="${GIT_COMMITTER_EMAIL:-$email}"
fi

# ALCF tokens last 48 hours. If you have run `alcf-tokens login inference` on this machine, get a fresh one.
if command -v alcf-tokens >/dev/null 2>&1; then
  if token="$(alcf-tokens get-token inference </dev/null 2>/dev/null)" && [[ -n "$token" ]]; then
    export ALCF_AI_TOKEN="$token"
  fi
fi

# Pass model-access settings from your shell into the container when they are set. `-e NAME` copies
# the value without putting it on the command line. AMSC_* holds the MAG token, ALCF_* the ALCF token.
# GH_TOKEN is passed only if you set it yourself, e.g. GH_TOKEN=$(gh auth token) ./run.sh
passthrough=(
  ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_BASE_URL ANTHROPIC_CUSTOM_HEADERS
  ANTHROPIC_MODEL ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL ANTHROPIC_DEFAULT_HAIKU_MODEL
  CLAUDE_CODE_SUBAGENT_MODEL CLAUDE_CODE_MAX_OUTPUT_TOKENS CLAUDE_CODE_AUTO_COMPACT_WINDOW
  CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS CLAUDE_CODE_NO_FLICKER
  DISABLE_TELEMETRY DISABLE_NON_ESSENTIAL_MODEL_CALLS
  OPENAI_API_KEY OPENAI_BASE_URL OPENROUTER_API_KEY I2CORE_API_KEY
  GH_TOKEN
  GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
)
for name in "${passthrough[@]}" $(compgen -e | grep -E '^(AMSC|ALCF)_' || true); do
  [[ -n "${!name:-}" ]] && args+=(-e "$name")
done

# Make dev (UID/GID 1000 in the image) own the mounted project, so the agent can edit it and
# the files stay yours on the host. Docker Desktop (macOS, Windows) already takes care of this.
renumber=false
if [[ "$("$ENGINE" --version 2>/dev/null)" == podman* ]] \
    && [[ "$("$ENGINE" info -f '{{.Host.Security.Rootless}}' 2>/dev/null)" == true ]]; then
  # Rootless Podman: map your user to dev. Podman before 4.3 (e.g. Ubuntu 22.04) has no keep-id:uid=,
  # so there keep-id maps your user to your own UID and entrypoint.sh renumbers dev to match.
  IFS=. read -r major minor _ <<<"$("$ENGINE" info -f '{{.Version.Version}}' 2>/dev/null)"
  if (( ${major:-0} > 4 || (${major:-0} == 4 && ${minor:-0} >= 3) )); then
    args+=(--userns=keep-id:uid=1000,gid=1000)
  else
    args+=(--userns=keep-id)
    [[ "$(id -u):$(id -g)" != 1000:1000 ]] && renumber=true
  fi
elif [[ "$(uname -s)" == Linux && "$(id -u)" != 0 && "$(id -u):$(id -g)" != 1000:1000 ]]; then
  renumber=true
fi
if $renumber; then
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
