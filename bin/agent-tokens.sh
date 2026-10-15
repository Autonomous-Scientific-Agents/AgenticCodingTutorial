# Token helpers shared by the {claude,codex,opencode}-{amsc,alcf} commands. Source this file; do not run it.
# The commands work in the tutorial container and on your own machine (bash 3.2 or newer, curl).
#
#   require_amsc_token   AMSC_TOKEN (MAG PAT) from the host, or ask for one in a terminal (this session only)
#   require_alcf_token   ALCF_AI_TOKEN from the host, or from alcf-tokens, logging in first in a terminal
#   exec_opencode        start opencode so that it reads OPENCODE_CONFIG_CONTENT

MAG_URL=https://mag.genesis.americansciencecloud.org
ALCF_URL=https://inference-api.alcf.anl.gov/resource_server
_cmd="${0##*/}"

_interactive() { [[ -t 0 && -t 1 ]]; }
in_container() { [[ -n "${AGENTIC_CODING_CONTAINER:-}" ]]; }

# What to do after changing a variable on the host.
if in_container; then _restart="restart the container"; else _restart="open a new terminal"; fi

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
  macOS / Linux: add  export AMSC_TOKEN=<your PAT>  to ~/.zshrc or ~/.bashrc, then open a new terminal.
  Windows:       [Environment]::SetEnvironmentVariable('AMSC_TOKEN', '<your PAT>', 'User'), then open a new terminal.
EOF
}

# HTTP status of a MAG request with this PAT (000 when MAG cannot be reached).
_mag_check() {
  curl -s -o /dev/null -w '%{http_code}' -m 10 -H "Authorization: Bearer $1" "$MAG_URL/v1/models" || true
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
    if in_container; then echo "Using this PAT until the container stops." >&2; else echo "Using this PAT for this run only." >&2; fi
    _mag_host_steps
  elif _interactive && [[ "$(_mag_check "$AMSC_TOKEN")" =~ ^40[13]$ ]]; then
    echo "$_cmd: MAG rejected AMSC_TOKEN; PATs are short-lived, so it has probably expired." >&2
    _mag_steps
    _mag_ask || { echo "$_cmd: no valid PAT." >&2; exit 1; }
    echo "Using the new PAT for now. Update AMSC_TOKEN too, then $_restart." >&2
  fi
  export AMSC_TOKEN
}

_alcf_get_token() {
  command -v alcf-tokens >/dev/null 2>&1 || return 1
  ALCF_AI_TOKEN="$(alcf-tokens get-token inference </dev/null 2>/dev/null)" && [[ -n "$ALCF_AI_TOKEN" ]]
}

require_alcf_token() {
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
