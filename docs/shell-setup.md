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

PATs are short-lived. When MAG rejects yours, generate a new one, replace the line, and load it again
(`source ~/.bash_secrets && use-amsc` in a shell that is already open).

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

_MAG_URL=https://mag.genesis.americansciencecloud.org
_ALCF_URL=https://inference-api.alcf.anl.gov/resource_server/minerva/api   # Claude Code adds /v1/messages

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

ALCF tokens last 48 hours. If a shell has been on ALCF that long, run `use-alcf` again to get a fresh token.
`claude-alcf` gets a fresh token every time it starts.

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
