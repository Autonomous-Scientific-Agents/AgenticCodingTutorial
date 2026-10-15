# Shell setup

You can run Claude Code on MAG or on the ALCF Inference Endpoints straight from your shell. Two small files in
your home directory do it: one holds your tokens, the other defines the commands. The setup works the same in
bash and zsh, so you can use it on any Linux or macOS machine, including the login nodes of supercomputers at
ALCF, OLCF and NERSC.

!!! tip "Prefer an isolated setup? Use the container"
    The [tutorial container](container.md) has the same `claude-amsc` and `claude-alcf` commands (plus Codex
    and OpenCode versions) built in, and the agent sees only the project folder you mount. It needs Podman or
    Docker, which shared systems such as supercomputers often do not provide. There, and on any machine where
    you already work in a shell, use the setup on this page.

The MAG settings come from the AmSC guide
[Claude Code with MAG](https://docs.amsc.energy.gov/client-applications/coding-tools/claude-code/), which also
defines a `claude-amsc` shell function. This page uses the same variables and adds a way to switch back and forth
with ALCF. If AmSC changes its recommendations, follow the AmSC guide.

!!! warning "Check the AI policy first"
    Before you use a coding agent on a shared system, read your facility's user policy and your institution's
    guidance on AI tools. Find out which models and services you may use, and what data may leave the
    machine. The agent sends your prompts, the files it reads and the command output it sees to the model
    provider. Do not point it at export-controlled, proprietary, personal or otherwise restricted data unless
    you have permission. MAG users must also follow the [AmSC policies](https://docs.amsc.energy.gov/Policies/acknowledgement).

The setup has five steps. Each one ends with a check.

1. Install Claude Code (and, for ALCF, `alcf-tokens`).
2. Put your MAG token in `~/.bash_secrets`.
3. Add the agent commands to `~/.bash_functions`.
4. Load both files in your shell startup file, and in the current shell.
5. Run `claude-amsc` or `claude-alcf`, or switch the shell with `use-amsc`, `use-alcf` and `use-default`.

The file names are only a convention; zsh users can keep them. Steps 2 to 4 **add to** files you may already
have. They never overwrite them.

## 1. Install the tools

You do not need administrator rights. The installers put their programs in `~/.local/bin`.

```bash
curl -fsSL https://claude.ai/install.sh | bash     # Claude Code
```

For ALCF you also need uv and `alcf-tokens`. Skip this if you only use MAG:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh    # uv
```

**Open a new terminal** so it finds `uv`, then run:

```bash
uv tool install alcf-tokens                        # ALCF login helper
```

**Check:** `claude --version` (and `alcf-tokens --help` for ALCF) prints output. If you see
`command not found`, open a new terminal. If it still fails, add `export PATH="$HOME/.local/bin:$PATH"` to
`~/.bashrc` or `~/.zshrc`.

## 2. Store your MAG token in `~/.bash_secrets`

Only MAG needs a stored token. Get a MAG personal access token (PAT) from the
[myAmSC dashboard](https://my.amsc.energy.gov/dashboard): select your Genesis Mission project, then
**Personal Access Tokens** › **Generate PAT**. The token is shown only once, so copy it then. The AmSC page
[Get started with MAG](https://docs.amsc.energy.gov/mag-get-started) covers requesting access and creating tokens.

Create the file if it does not exist, make it readable only by you, and open it in an editor:

```bash
touch ~/.bash_secrets && chmod 600 ~/.bash_secrets
nano ~/.bash_secrets      # or vim, emacs, code
```

Add this line at the end, with your PAT between the quotes. If the file already has an `AMSC_TOKEN` line,
replace that line instead.

```bash
export AMSC_TOKEN='<your MAG PAT>'
```

Use an editor rather than `echo ... >> ~/.bash_secrets`. A command line with the token in it ends up in your
shell history.

**Check:** `ls -l ~/.bash_secrets` starts with `-rw-------`.

PATs are short-lived; see [When a token expires](#when-a-token-expires) for how to replace it.

For ALCF there is nothing to store. `alcf-tokens` keeps your login in `~/.globus` and gives out fresh tokens when
asked. Log in once, and again when ALCF asks (every 30 days):

```bash
alcf-tokens login inference
```

The command prints a Globus link. Open it in a browser on any computer, log in with your ALCF account, and paste
the code back into the terminal.

## 3. Add the commands to `~/.bash_functions`

First check that you have no older commands with the same names. The AmSC guide, for example, has you define a
`claude-amsc` function:

```bash
type claude-amsc claude-alcf use-amsc use-alcf 2>/dev/null
```

If this prints `function` or `alias` for a name, delete that older definition from your startup files first. A
file path, such as this repository's `bin/claude-amsc`, can stay.

Then copy this whole block into your terminal. It **appends** the commands to `~/.bash_functions` and creates the
file if needed. Whatever the file already contains stays. Run it only once; to change the commands later, see
[Update or remove](#update-or-remove).

```bash
cat >> ~/.bash_functions <<'EOF'

# >>> agent backends >>>
# Claude Code on MAG or the ALCF Inference Endpoints. Works in bash and zsh.
#   use-amsc | use-alcf | use-default   switch this shell; then run plain `claude`
#   claude-amsc | claude-alcf [args]    run Claude Code once on that backend; this shell is unchanged
#   agent-backend                       show which backend this shell uses
#   agent-status --check                ask MAG and ALCF whether your tokens work
#   agent-status --models | --hot       list MAG and ALCF models | only the ALCF models loaded now

_MAG_URL=https://mag.genesis.americansciencecloud.org
_ALCF_URL=https://inference-api.alcf.anl.gov/resource_server/minerva/api   # Claude Code adds /v1/messages
_ALCF_API=https://inference-api.alcf.anl.gov/resource_server

use-default() {
  unset ANTHROPIC_AUTH_TOKEN ANTHROPIC_BASE_URL ANTHROPIC_MODEL \
    ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL ANTHROPIC_DEFAULT_HAIKU_MODEL \
    CLAUDE_CODE_SUBAGENT_MODEL CLAUDE_CODE_MAX_OUTPUT_TOKENS CLAUDE_CODE_AUTO_COMPACT_WINDOW \
    DISABLE_NON_ESSENTIAL_MODEL_CALLS DISABLE_TELEMETRY CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS \
    CLAUDE_CODE_NO_FLICKER
  # Bring back an Anthropic API key that use-amsc or use-alcf set aside.
  if [ -n "${_SAVED_ANTHROPIC_API_KEY:-}" ]; then
    export ANTHROPIC_API_KEY="$_SAVED_ANTHROPIC_API_KEY"
    unset _SAVED_ANTHROPIC_API_KEY
  fi
  export AGENT_BACKEND=default
}

# Set aside ANTHROPIC_API_KEY: Claude Code would send it instead of the MAG or ALCF token.
_agent_switch() {
  use-default
  if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    export _SAVED_ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY"
    unset ANTHROPIC_API_KEY
  fi
  export DISABLE_NON_ESSENTIAL_MODEL_CALLS=1 DISABLE_TELEMETRY=1 CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1
}

use-amsc() {
  if [ -z "${AMSC_TOKEN:-}" ]; then
    echo "use-amsc: AMSC_TOKEN is not set. Add it to ~/.bash_secrets and open a new terminal." >&2
    return 1
  fi
  _agent_switch
  # Settings from https://docs.amsc.energy.gov/client-applications/coding-tools/claude-code/
  # No model variables: Claude Code picks current Claude models; use /model or --model to change.
  export ANTHROPIC_AUTH_TOKEN="$AMSC_TOKEN" ANTHROPIC_BASE_URL="$_MAG_URL" CLAUDE_CODE_NO_FLICKER=1
  # Smaller outputs avoid throttling; earlier compaction keeps long-context prices down (100000 for Haiku).
  export CLAUDE_CODE_MAX_OUTPUT_TOKENS=16384 CLAUDE_CODE_AUTO_COMPACT_WINDOW=200000
  export AGENT_BACKEND=amsc
}

use-alcf() {
  local token model="${ALCF_CLAUDE_MODEL:-inkling-bf16}"
  if ! command -v alcf-tokens >/dev/null 2>&1; then
    echo "use-alcf: alcf-tokens not found. Install it: uv tool install alcf-tokens" >&2
    return 1
  fi
  token="$(alcf-tokens get-token inference 2>/dev/null)"
  if [ -z "$token" ]; then
    echo "use-alcf: no ALCF token. Run: alcf-tokens login inference" >&2
    return 1
  fi
  _agent_switch
  export ALCF_AI_TOKEN="$token" ANTHROPIC_AUTH_TOKEN="$token" ANTHROPIC_BASE_URL="$_ALCF_URL"
  export ANTHROPIC_MODEL="$model" ANTHROPIC_DEFAULT_OPUS_MODEL="$model" \
    ANTHROPIC_DEFAULT_SONNET_MODEL="$model" ANTHROPIC_DEFAULT_HAIKU_MODEL="$model" \
    CLAUDE_CODE_SUBAGENT_MODEL="$model"
  export AGENT_BACKEND=alcf
}

# The ( ) body runs in a subshell, so the switch ends when Claude Code exits.
claude-amsc() ( use-amsc && command claude "$@" )
claude-alcf() ( use-alcf && command claude "$@" )

agent-backend() {
  echo "${AGENT_BACKEND:-default} (${ANTHROPIC_BASE_URL:-Anthropic, with your own login or API key})"
}

# HTTP status for a token: 200 works, 401 or 403 rejected, 000 no answer.
# The header goes in on stdin, so the token does not show up in the process list.
# With a third argument the body is saved to that file.
_agent_http() {
  local limit=10
  [ -n "${3:-}" ] && limit=20
  printf 'Authorization: Bearer %s\n' "$1" | curl -s -o "${3:-/dev/null}" -w '%{http_code}' -m "$limit" -H @- "$2" || true
}

_agent_report() {
  case "$2" in
    200) echo "$1: valid" ;;
    401|403) echo "$1: rejected (HTTP $2), expired or invalid. Renew: $3" ;;
    000) echo "$1: no answer (network, proxy or service down)" ;;
    *) echo "$1: unexpected answer (HTTP $2)" ;;
  esac
  [ "$2" = 200 ]
}

# MAG answers /v1/models in the OpenAI format.
_AGENT_MAG_PY='
import json, sys
try:
    models = sorted(m["id"] for m in json.load(sys.stdin).get("data") or [])
except (ValueError, KeyError, TypeError, AttributeError):
    sys.exit("MAG: unexpected answer to /v1/models (not a model list)")
print("MAG:")
for model in models:
    print("  " + model)
'

# ALCF: list-endpoints names the models; <cluster>/jobs says which are running (hot or starting) or queued.
_AGENT_ALCF_PY='
import json, os, re, sys
folder, mode = sys.argv[1], sys.argv[2]
def load(name):
    try:
        with open(os.path.join(folder, name)) as f:
            return json.load(f)
    except (IOError, ValueError):
        return None
rank = {"hot": 0, "starting": 1, "queued": 2, "offline": 3, "unknown": 4}
def names(value):
    items = value if isinstance(value, list) else str(value or "").split(",")
    return [str(m).strip() for m in items if str(m).strip()]
def table(value):
    return value if isinstance(value, dict) else {}
endpoints = load("endpoints.json")
clusters = endpoints.get("clusters") if isinstance(endpoints, dict) else None
# "clusters" prints the names for the shell to fetch <cluster>/jobs; it stays quiet, the listing reports errors.
if mode == "clusters":
    print(" ".join(c for c in table(clusters) if re.match(r"^[A-Za-z0-9_-]+$", c)))
    sys.exit()
if not isinstance(clusters, dict):
    sys.exit("ALCF: unexpected answer to list-endpoints (no cluster list)")
print("ALCF (hot: loaded now; starting or queued: loading; offline: loads on the first request, which can take minutes; unknown: no live status):")
for cluster in sorted(clusters):
    jobs = load("jobs-" + cluster + ".json")
    known = isinstance(jobs, dict)
    # Keyed by (framework, model); a job that names no framework counts for every framework.
    state = {}
    for key in ("running", "queued"):
        for job in (jobs if known else {}).get(key) or []:
            if not isinstance(job, dict):
                continue
            status = "queued"
            if key == "running":
                ready = str(job.get("Model Status") or "").lower()
                status = "hot" if ready in ("ready", "running", "live") else "starting"
            framework = str(job.get("Framework") or "").lower()
            for model in names(job.get("Models")):
                if rank[status] < rank[state.get((framework, model), "offline")]:
                    state[(framework, model)] = status
    note = "" if known else ", live status unavailable"
    for framework, info in sorted(table(table(clusters[cluster]).get("frameworks")).items()):
        def status_of(m):
            if not known:
                return "unknown"
            return min(state.get((framework.lower(), m), "offline"), state.get(("", m), "offline"), key=rank.get)
        models = sorted(set(table(info).get("models") or []), key=lambda m: (rank[status_of(m)], m.lower()))
        hot = [m for m in models if status_of(m) == "hot"]
        if mode == "hot":
            print("%s (%s): %d hot%s" % (cluster, framework, len(hot), note))
            models = hot
        else:
            print("%s (%s): %d model%s, %d hot%s" % (cluster, framework, len(models), "" if len(models) == 1 else "s", len(hot), note))
        for model in models:
            print("  %-8s  %s" % (status_of(model), model))
'

# $1 is "all" (MAG and ALCF) or "hot" (only ALCF models that are loaded now).
# The ( ) body runs in a subshell, so the trap removes the temporary folder even after Ctrl-C.
_agent_models() (
  local folder code token cluster rc=0
  if ! command -v python3 >/dev/null 2>&1; then
    echo "agent-status: listing models needs python3" >&2
    return 1
  fi
  folder="$(mktemp -d)" || return 1
  trap 'rm -rf "$folder"' EXIT
  if [ "$1" = all ]; then
    if [ -z "${AMSC_TOKEN:-}" ]; then
      echo "MAG: no AMSC_TOKEN. Add it to ~/.bash_secrets"
    else
      code="$(_agent_http "$AMSC_TOKEN" "$_MAG_URL/v1/models" "$folder/mag.json")"
      if [ "$code" = 200 ]; then
        python3 -c "$_AGENT_MAG_PY" < "$folder/mag.json" || rc=1
      else
        _agent_report MAG "$code" "read -rs AMSC_TOKEN && export AMSC_TOKEN, then update ~/.bash_secrets" || rc=1
      fi
    fi
  fi
  if ! command -v alcf-tokens >/dev/null 2>&1; then
    echo "ALCF: alcf-tokens not installed (uv tool install alcf-tokens)"
    rc=1
  elif ! token="$(alcf-tokens get-token inference 2>/dev/null)" || [ -z "$token" ]; then
    echo "ALCF: not logged in. Log in: alcf-tokens login inference"
    rc=1
  else
    code="$(_agent_http "$token" "$_ALCF_API/list-endpoints" "$folder/endpoints.json")"
    if [ "$code" != 200 ]; then
      _agent_report ALCF "$code" "alcf-tokens login inference" || rc=1
    else
      for cluster in $(python3 -c "$_AGENT_ALCF_PY" "$folder" clusters); do
        # All clusters at once, so a slow service costs one timeout rather than one per cluster.
        { [ "$(_agent_http "$token" "$_ALCF_API/$cluster/jobs" "$folder/jobs-$cluster.json")" = 200 ] ||
          rm -f "$folder/jobs-$cluster.json"; } &
      done
      wait
      python3 -c "$_AGENT_ALCF_PY" "$folder" "$1" || rc=1
    fi
  fi
  return "$rc"
)

agent-status() {
  local token rc=0
  case "${1:-}" in
    "")
      agent-backend
      echo "Test your tokens: agent-status --check. List models: agent-status --models" ;;
    --check)
      if [ -n "${AMSC_TOKEN:-}" ]; then
        _agent_report MAG "$(_agent_http "$AMSC_TOKEN" "$_MAG_URL/v1/models")" \
          "read -rs AMSC_TOKEN && export AMSC_TOKEN, then update ~/.bash_secrets" || rc=1
      else
        echo "MAG: no AMSC_TOKEN. Add it to ~/.bash_secrets"
      fi
      if ! command -v alcf-tokens >/dev/null 2>&1; then
        echo "ALCF: alcf-tokens not installed (uv tool install alcf-tokens)"
      elif token="$(alcf-tokens get-token inference 2>/dev/null)" && [ -n "$token" ]; then
        _agent_report ALCF "$(_agent_http "$token" "$_ALCF_API/list-endpoints")" "alcf-tokens login inference" || rc=1
      else
        echo "ALCF: not logged in. Log in: alcf-tokens login inference"
      fi
      return "$rc" ;;
    --models) _agent_models all ;;
    --hot) _agent_models hot ;;
    *) echo "usage: agent-status [--check | --models | --hot]" >&2; return 2 ;;
  esac
}
# <<< agent backends <<<
EOF
```

**Check:** `grep -c '>>> agent backends' ~/.bash_functions` prints `1`. If it prints `2`, you ran the block twice;
see [Update or remove](#update-or-remove) to remove both and add one again.

## 4. Load both files

Your shell reads its startup file only when it starts, so this step has two parts.

**Load them in every new shell.** Pick your shell. The command adds a line for each file to your startup file,
unless the line is already there:

=== "bash"

    ```bash
    for f in bash_secrets bash_functions; do
      grep -q "\. ~/\.$f" ~/.bashrc 2>/dev/null || echo "[ -f ~/.$f ] && . ~/.$f" >> ~/.bashrc
    done
    ```

=== "zsh (macOS default)"

    ```bash
    for f in bash_secrets bash_functions; do
      grep -q "\. ~/\.$f" ~/.zshrc 2>/dev/null || echo "[ -f ~/.$f ] && . ~/.$f" >> ~/.zshrc
    done
    ```

The added lines look like `[ -f ~/.bash_functions ] && . ~/.bash_functions`: load the file if it exists. If your
startup file already loads these files in some other way, the extra line is harmless.

**Load them in the shell you have open now.** Without this, the commands exist only in new terminals:

```bash
source ~/.bash_secrets
source ~/.bash_functions
```

Opening a new terminal does the same thing. Do it again whenever you edit either file.

**Check:** `agent-backend` prints `default (Anthropic, with your own login or API key)`, and
`echo ${AMSC_TOKEN:+AMSC_TOKEN is set}` prints `AMSC_TOKEN is set`.

!!! note "Login shells on clusters"
    When you connect with SSH you get a login shell. A bash login shell reads `~/.bash_profile` and not
    `~/.bashrc`. Most sites source `~/.bashrc` from their default `~/.bash_profile`. If `agent-backend` is
    `command not found` after you log in, add `[ -f ~/.bashrc ] && . ~/.bashrc` to `~/.bash_profile`.

## 5. Use and switch

Run once on a backend. Claude Code options work as usual:

```bash
cd my-project
claude-amsc                              # Claude Code on MAG
claude-amsc --model claude-haiku         # a cheaper MAG model; run /autocompact 100000 in the session
claude-alcf                              # Claude Code on ALCF (inkling-bf16)
ALCF_CLAUDE_MODEL=<model> claude-alcf    # another ALCF model
```

Or switch the current shell, so that plain `claude` uses that backend. Other programs you start from this shell
use it too.

```bash
use-alcf && claude      # this shell now uses ALCF
agent-backend           # alcf (https://inference-api.alcf.anl.gov/...)
use-amsc                # now MAG
use-default             # back to your own Claude subscription or API key
```

To see what a backend sets, run `type claude-amsc` or
`env | grep -E '^(ANTHROPIC_|CLAUDE_CODE_|DISABLE_)'`, as the AmSC guide suggests.

!!! warning "MAG usage is charged to your project"
    The AmSC guide notes that Claude Code can easily use more than $100 a day, and that this counts against
    your project allocation. Watch your spend on the [MAG dashboard](https://docs.amsc.energy.gov/mag-dashboard),
    and use cheaper models for routine work (see AmSC's
    [Model Recommendations](https://docs.amsc.energy.gov/model-selection)).

### Which models you can use

```bash
agent-status --models     # MAG and ALCF models
agent-status --hot        # only the ALCF models that are loaded now
```

```text
ALCF (hot: loaded now; starting or queued: loading; offline: loads on the first request, which can take minutes; unknown: no live status):
minerva (api): 3 models, 1 hot
  hot       inkling-bf16
  offline   gpt-oss-120b
  offline   nemotron-3-ultra
sophia (vllm): ...
```

ALCF serves a model from its own nodes only while it is loaded. A model marked `offline` still works, but the first
request starts it and can wait minutes in the queue. Pick a hot one with `ALCF_CLAUDE_MODEL=<model> claude-alcf`.
`claude-alcf` and `use-alcf` use Minerva, so pick from its list. For MAG, pass a listed name to `--model`.
These commands need `python3`; the raw data is also available from `alcf-ai ls-endpoints` and
`alcf-ai ls-jobs <cluster>`.

### When a token expires

MAG PATs are short-lived, ALCF access tokens last 48 hours, and the ALCF login itself lasts 30 days. To see
whether your tokens still work:

```bash
agent-status --check
```

```text
MAG: rejected (HTTP 401), expired or invalid. Renew: read -rs AMSC_TOKEN && export AMSC_TOKEN, then update ~/.bash_secrets
ALCF: valid
```

It asks MAG and ALCF directly and never prints the tokens.

**New MAG PAT.** Create one on the [myAmSC dashboard](https://my.amsc.energy.gov/dashboard) and copy it. Then:

1. Use it in the shell you have open now. Run the line below, paste the PAT (nothing appears while you paste)
   and press Enter:

    ```bash
    read -rs AMSC_TOKEN && export AMSC_TOKEN
    use-amsc        # only if this shell was switched to MAG
    ```

    `read` keeps the PAT out of your shell history; `export AMSC_TOKEN=<PAT>` works too, but is saved there.

2. Keep it for new terminals: replace the `AMSC_TOKEN` line in `~/.bash_secrets` (step 2).

**ALCF.** Usually nothing to do: `claude-alcf` gets a fresh token every time it starts, and so does `use-alcf`
(run it again in a shell that has been on ALCF for 48 hours). When the 30-day login runs out, log in again:

```bash
alcf-tokens login inference
```

!!! tip "Things that override these settings"
    - `env` entries in `~/.claude/settings.json` or in a project's `.claude/settings.json` take precedence over your
      shell. For example, `alcf-ai agent configure claude` writes such entries. Remove them if you want
      these commands to choose the backend.
    - If the repository's `bin` folder is also on your `PATH`, the functions win, because the shell looks up
      functions before programs. Both versions do the same job. The `bin` commands also cover Codex and OpenCode
      (see [Shortcut commands](getting-started.md#shortcut-commands-for-mag-and-alcf)).
    - The AmSC guide documents an optional provider header. To use it, export
      `ANTHROPIC_CUSTOM_HEADERS="X-AmSC-MAG-Provider: amazon"` before running `claude-amsc`; these functions do
      not touch it.

## Update or remove

The commands sit between the `# >>> agent backends >>>` and `# <<< agent backends <<<` lines in
`~/.bash_functions`. This deletes that block and nothing else, and keeps a copy in `~/.bash_functions.bak`:

```bash
sed -i.bak '/^# >>> agent backends >>>$/,/^# <<< agent backends <<<$/d' ~/.bash_functions
```

- **To update:** run it, copy the current block from [step 3](#3-add-the-commands-to-bash_functions), then open
  a new terminal.
- **To remove:** run it, then delete the `AMSC_TOKEN` line from `~/.bash_secrets`. Delete the two lines that step 4
  added to `~/.bashrc` or `~/.zshrc` if nothing else uses those files.

## On supercomputers (ALCF, OLCF, NERSC)

The same steps work on the login nodes of Polaris and Aurora (ALCF), Frontier (OLCF), Perlmutter (NERSC) and
other Linux clusters. Follow steps 1 to 4 on the cluster as on your own machine; on a login node, use the bash tab in step 4.

- **Read the policy first.** See the warning at the top of this page. Facility policies differ, and project or
  allocation terms can add limits on top of them.
- **Run the agent on a login node.** It needs outbound HTTPS to MAG or ALCF. Compute nodes often have no outbound
  network, or reach it only through a site proxy. Check your facility's documentation before running there.
- **Respect login-node limits.** Claude Code itself uses little CPU, but the commands it runs (builds, tests,
  analysis) count against login-node usage rules. Ask it to submit batch jobs for real work, and review those
  scripts before they run.
- **Keep the token private.** Home directories on clusters are on shared file systems, so check that
  `ls -l ~/.bash_secrets` shows `-rw-------`. Do not keep it in a dotfiles repository, and do not type it into a
  command line, where other users can see it in the process list.
- **Mind your home quota.** Claude Code keeps sessions in `~/.claude`, and uv keeps a cache in `~/.cache/uv`.
  If your home space is small, clean these up from time to time.

## AmSC and ALCF documentation

This page builds on the AmSC MAG documentation. Check it for current settings, models and policies:

- [Claude Code with MAG](https://docs.amsc.energy.gov/client-applications/coding-tools/claude-code/): the
  source of the MAG variables used here, and the original `claude-amsc` function
- [Coding tools](https://docs.amsc.energy.gov/client-applications/coding-tools/): MAG setup for
  [Codex](https://docs.amsc.energy.gov/client-applications/coding-tools/codex),
  [OpenCode](https://docs.amsc.energy.gov/client-applications/coding-tools/opencode) and other tools
- [Model Access Gateway](https://docs.amsc.energy.gov/model-access-gateway) and
  [Get started with MAG](https://docs.amsc.energy.gov/mag-get-started)
- [Model names and options](https://docs.amsc.energy.gov/model-names) and
  [Model Recommendations](https://docs.amsc.energy.gov/model-selection)
- [MAG dashboard](https://docs.amsc.energy.gov/mag-dashboard),
  [Troubleshooting](https://docs.amsc.energy.gov/mag-troubleshooting), [FAQ](https://docs.amsc.energy.gov/faq)
  and [Support](https://docs.amsc.energy.gov/support/)
- [AmSC policies](https://docs.amsc.energy.gov/Policies/acknowledgement)

For ALCF, see the [ALCF Inference Endpoints documentation](https://docs.alcf.anl.gov/services/inference-endpoints)
and its [coding agents guide](https://docs.alcf.anl.gov/services/inference-endpoints/agents/).
