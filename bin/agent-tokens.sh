# Token helpers shared by the {claude,codex,opencode}-{amsc,alcf} commands. Source this file; do not run it.
# The commands work in the tutorial container and on your own machine (bash 3.2 or newer, curl).
#
#   require_amsc_token   AMSC_TOKEN (MAG PAT) from the host, or ask for one in a terminal (this run only)
#   require_alcf_token   ALCF_AI_TOKEN from the host while ALCF accepts it, else from alcf-tokens,
#                        logging in first in a terminal
#   alcf_model <name>    set ALCF_MODEL and ALCF_PATH, the name and cluster that serve this model to agents
#   exec_opencode        start opencode so that it reads OPENCODE_CONFIG_CONTENT

MAG_URL=https://mag.genesis.americansciencecloud.org
ALCF_URL=https://inference-api.alcf.anl.gov/resource_server
_cmd="${0##*/}"

_interactive() { [[ -t 0 && -t 1 ]]; }
in_container() { [[ -n "${AGENTIC_CODING_CONTAINER:-}" ]]; }

_mag_steps() {
  cat >&2 <<'EOF'
To get a MAG personal access token (PAT):
  1. Open https://my.amsc.energy.gov/dashboard and select your Genesis Mission project.
  2. Select Personal Access Tokens, then Generate PAT, and copy it (it is shown only once).
  Details: https://docs.amsc.energy.gov/mag-get-started
EOF
}

_mag_host_steps() {
  local where="in your shell startup file"
  in_container && where="on your host, then restart the container"
  cat >&2 <<EOF
To have it set automatically, store the PAT $where:
  macOS / Linux: add  export AMSC_TOKEN='<your PAT>'  to ~/.zshrc or ~/.bashrc, then open a new terminal.
  Windows:       [Environment]::SetEnvironmentVariable('AMSC_TOKEN', '<your PAT>', 'User'), then open a new terminal.
EOF
}

# HTTP status of a request with this token (000 when there is no answer). The header goes in on stdin,
# so the token does not show up in the process list. With a third argument the body is saved to that file.
_http_status() {
  local limit=10
  [[ -n "${3:-}" ]] && limit=20
  printf 'Authorization: Bearer %s\n' "$1" | curl -s -o "${3:-/dev/null}" -w '%{http_code}' -m "$limit" -H @- "$2" || true
}

# HTTP status of a MAG request with this PAT.
_mag_check() { _http_status "$1" "$MAG_URL/v1/models"; }

# HTTP status of an ALCF request with this token.
_alcf_check() { _http_status "$1" "$ALCF_URL/list-endpoints"; }

# Said after a pasted PAT is accepted: it lasts for this run, and how to keep it.
_mag_kept() {
  cat >&2 <<'EOF'
Using this PAT for this run only. To use it for the rest of this shell, paste it once more here:
  read -rs AMSC_TOKEN && export AMSC_TOKEN
EOF
}

_mag_ask() {
  local pat status
  for _ in 1 2 3; do
    read -rsp "Paste your MAG PAT (input is hidden): " pat </dev/tty || true
    echo >&2
    [[ -n "$pat" ]] || continue
    status="$(_mag_check "$pat")"
    case "$status" in
      200) AMSC_TOKEN="$pat"; return 0 ;;
      401|403) echo "MAG rejected this PAT (invalid or expired). Generate a new one and try again." >&2 ;;
      *) echo "Could not verify the PAT (HTTP $status); using it anyway." >&2; AMSC_TOKEN="$pat"; return 0 ;;
    esac
  done
  return 1
}

require_amsc_token() {
  if [[ -z "${AMSC_TOKEN:-}" ]]; then
    echo "$_cmd: AMSC_TOKEN is not set." >&2
    _mag_steps
    if ! _interactive; then
      _mag_host_steps
      exit 1
    fi
    _mag_ask || { echo "$_cmd: no valid PAT." >&2; exit 1; }
    _mag_kept
    _mag_host_steps
  elif _interactive && [[ "$(_mag_check "$AMSC_TOKEN")" =~ ^40[13]$ ]]; then
    echo "$_cmd: MAG rejected AMSC_TOKEN; PATs are short-lived, so it has probably expired." >&2
    _mag_steps
    _mag_ask || { echo "$_cmd: no valid PAT." >&2; exit 1; }
    _mag_kept
    _mag_host_steps
  fi
  export AMSC_TOKEN
}

# Minerva serves inkling-bf16 and nemotron-3-ultra. Gemma 4 31B runs on Sophia's vLLM (Metis has it too, but
# its tool calls have known issues). Only OpenCode can use it there: Sophia does not stream Anthropic Messages,
# which Claude Code needs, and its Responses API returns Gemma's tool calls as text, which breaks Codex.
alcf_model() {
  case "$1" in
    gemma-4-31B-it|google/gemma-4-31B-it) ALCF_MODEL=google/gemma-4-31B-it ALCF_PATH=sophia/vllm ;;
    *) ALCF_MODEL="$1" ALCF_PATH=minerva/api ;;
  esac
}

_alcf_get_token() {
  command -v alcf-tokens >/dev/null 2>&1 || return 1
  ALCF_AI_TOKEN="$(alcf-tokens get-token inference </dev/null 2>/dev/null)" && [[ -n "$ALCF_AI_TOKEN" ]]
}

require_alcf_token() {
  # A token passed in from the host lasts 48 hours; once ALCF rejects it, fall back to alcf-tokens.
  if [[ -n "${ALCF_AI_TOKEN:-}" ]] && _interactive && [[ "$(_alcf_check "$ALCF_AI_TOKEN")" =~ ^40[13]$ ]]; then
    echo "$_cmd: ALCF rejected ALCF_AI_TOKEN (tokens last 48 hours); getting a new one." >&2
    unset ALCF_AI_TOKEN
  fi
  if [[ -z "${ALCF_AI_TOKEN:-}" ]] && ! _alcf_get_token; then
    if _interactive && ! command -v alcf-tokens >/dev/null 2>&1; then
      echo "$_cmd: alcf-tokens is not installed. Install it with: uv tool install alcf-tokens" >&2
      exit 1
    elif _interactive; then
      cat >&2 <<EOF
$_cmd: you are not logged in to the ALCF Inference Endpoints yet.
You need an ALCF account. alcf-tokens prints a Globus login link:
  1. Open the link in your browser and log in with your ALCF account.
  2. Copy the authorization code Globus shows and paste it here.
The login is kept, so you only do this again when ALCF asks (every 30 days).

EOF
      alcf-tokens login inference
      _alcf_get_token || { echo "$_cmd: still no token; try 'alcf-tokens login inference' again." >&2; exit 1; }
    else
      cat >&2 <<EOF
$_cmd: no ALCF token. Either:
  - run $_cmd in an interactive terminal and follow the login prompt, or
  - run: alcf-tokens login inference   (install it with: uv tool install alcf-tokens), then run $_cmd again.
Details: https://docs.alcf.anl.gov/services/inference-endpoints
EOF
      exit 1
    fi
  fi
  export ALCF_AI_TOKEN
}

# OpenCode 2 runs a shared background service that never sees OPENCODE_CONFIG_CONTENT; --standalone starts
# a private one that does. The flag goes after the subcommand. OpenCode 1 reads the variable directly.
exec_opencode() {
  local major
  major="$(opencode --version 2>/dev/null | sed -E 's/^[^0-9]*([0-9]+).*/\1/')"
  if [[ "$major" =~ ^[0-9]+$ ]] && (( major >= 2 )); then
    case "${1:-}" in
      run|mini|models|acp) exec opencode "$1" --standalone "${@:2}" ;;
      ""|-*) exec opencode --standalone "$@" ;;
      *) [[ -d "$1" ]] && exec opencode --standalone "$@" ;;
    esac
  fi
  exec opencode "$@"
}
