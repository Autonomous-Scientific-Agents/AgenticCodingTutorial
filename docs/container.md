# Run the agents in a container

The tutorial container has everything you need for the session:
Claude Code, Codex CLI and OpenCode, plus [uv](https://docs.astral.sh/uv/), git, the
[GitHub CLI](https://cli.github.com/) (`gh`), Python 3, the terminal editors vim, emacs and nano, and
VS Code in the browser ([code-server](https://github.com/coder/code-server)).

!!! success "Why a container is a safe place for an agent"
    The agent can only see the project folder you mount into it. It cannot read your home directory,
    SSH keys, or other projects, and anything it installs disappears when the container stops.
    Your work in the mounted folder is kept, so commit it with git as usual.
    Inside a container it is reasonable to allow more autonomy (fewer approval prompts) than on your laptop
    or on a shared allocation.

Image: `ghcr.io/autonomous-scientific-agents/agentic-coding:latest` (Linux amd64 and arm64, so it runs on
Intel and Apple-silicon machines).

## 1. Install Podman

We recommend [Podman](https://podman.io/): it is open source, free for everyone, and does not need a
background service running as root. [Docker](#docker-desktop-instead) works too.

=== "macOS"

    Download and run the installer from [podman.io](https://podman.io/docs/installation#macos)
    (or `brew install podman` if you use Homebrew). Podman runs containers in a small Linux virtual machine;
    create and start it once:

    ```bash
    podman machine init
    podman machine start
    ```

    After a restart, run `podman machine start` again before using the container.

=== "Windows"

    Podman uses WSL 2. In PowerShell:

    ```powershell
    winget install -e --id RedHat.Podman
    ```

    Open a new terminal, then create and start the Podman machine (if WSL is not installed yet, `init` offers
    to install it; restart and run `init` again):

    ```powershell
    podman machine init
    podman machine start
    ```

    After a restart, run `podman machine start` again before using the container.

=== "Linux"

    ```bash
    sudo apt update && sudo apt install -y podman     # Ubuntu / Debian
    # sudo dnf install -y podman                       # Fedora / RHEL
    ```

    No virtual machine is needed on Linux, and containers run as your own user.

Check that it works:

```bash
podman run --rm quay.io/podman/hello
```

Prefer a graphical app? [Podman Desktop](https://podman-desktop.io/) installs Podman and sets up the machine for you.

### Docker Desktop instead

[Docker Desktop](https://docs.docker.com/get-started/get-docker/) (macOS, Windows) or Docker Engine (Linux)
also works. Docker Desktop is free for personal use, education and small businesses, but larger organizations
need a paid subscription, so check with your institution. With Docker, write `docker` wherever this page
says `podman`.

The run script uses whichever of `podman` and `docker` is running, trying `podman` first. If both are
running, choose with `CONTAINER_ENGINE=docker` (PowerShell: `$env:CONTAINER_ENGINE = "docker"`).

## 2. Get the image and the run script

=== "macOS / Linux"

    ```bash
    podman pull ghcr.io/autonomous-scientific-agents/agentic-coding:latest
    curl -fsSLO https://raw.githubusercontent.com/Autonomous-Scientific-Agents/AgenticCodingTutorial/main/run.sh
    chmod +x run.sh
    ```

=== "Windows"

    In PowerShell, with the Podman machine running:

    ```powershell
    podman pull ghcr.io/autonomous-scientific-agents/agentic-coding:latest
    irm https://raw.githubusercontent.com/Autonomous-Scientific-Agents/AgenticCodingTutorial/main/run.ps1 -OutFile run.ps1
    ```

    `run.ps1` is the PowerShell version of `run.sh` and takes the same arguments: wherever this page says
    `/path/to/run.sh`, use `C:\path\to\run.ps1`. If PowerShell answers
    `running scripts is disabled on this system`, allow scripts for your user once with
    `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

    Working in WSL instead? Open your Ubuntu terminal and follow the **macOS / Linux** tab.

Prefer to build it yourself? Clone this repository and run `./run.sh build` (Windows: `.\run.ps1 build`).

## 3. Start it in your project

Run the script **from the project folder** you want the agent to work on. That folder appears as
`/workspace` inside the container, and nothing else from your machine does.

=== "macOS / Linux"

    ```bash
    cd my-project
    /path/to/run.sh            # a bash shell inside the container
    claude                     # or: codex, opencode
    ```

=== "Windows"

    ```powershell
    cd my-project
    C:\path\to\run.ps1         # a bash shell inside the container
    claude                     # or: codex, opencode
    ```

You can also start one tool directly: `/path/to/run.sh claude`.

### Editors

| Editor | How |
|---|---|
| vim, emacs, nano | run them in the container shell: `vim src/pgmol/api.py`, `emacs -nw …` |
| VS Code in the browser | `/path/to/run.sh code`, then open <http://localhost:8080> |
| VS Code on your desktop | copy [`.devcontainer/`](https://github.com/Autonomous-Scientific-Agents/AgenticCodingTutorial/tree/main/.devcontainer) into your project, install the *Dev Containers* extension, and run **Dev Containers: Reopen in Container** |

Files are shared, so you can also keep editing on your host with any editor while the agent runs in the
container.

## 4. Model access and logins

Keys and tokens stay on your machine: you set them as environment variables on the host, and the run script
copies them into the container each time it starts. They are never written into the image or the saved volumes.
The script passes these variables when they are set:

- any variable whose name starts with `AMSC_` (MAG) or `ALCF_` (ALCF)
- `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_BASE_URL`, `ANTHROPIC_CUSTOM_HEADERS`, `ANTHROPIC_MODEL`
  and the `ANTHROPIC_DEFAULT_{OPUS,SONNET,HAIKU}_MODEL` variables
- the Claude Code settings `CLAUDE_CODE_MAX_OUTPUT_TOKENS`, `CLAUDE_CODE_AUTO_COMPACT_WINDOW`,
  `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS`, `CLAUDE_CODE_NO_FLICKER`, `CLAUDE_CODE_SUBAGENT_MODEL`,
  `DISABLE_TELEMETRY` and `DISABLE_NON_ESSENTIAL_MODEL_CALLS`
- `OPENAI_API_KEY`, `OPENAI_BASE_URL`, `OPENROUTER_API_KEY`

Check what arrived from inside the container, without printing the values: `env | cut -d= -f1 | grep -E 'AMSC|ALCF|ANTHROPIC|OPENAI'`.

- **Subscription login:** run `claude` or `codex` and follow the login prompt. Logins and settings are stored in
  named volumes, so you sign in once. That covers `~/.claude` (including `.claude.json`: sign-in, trusted
  folders and MCP servers), `~/.codex`, and OpenCode's `~/.config/opencode` and `~/.local/share/opencode`.
- **GitHub:** see [GitHub and git](#github-and-git) below.

### AmSC Model Access Gateway (MAG)

For Genesis Mission teams. Follow [Get started with MAG](https://docs.amsc.energy.gov/mag-get-started) to get
a personal access token (PAT).

**1. Store the PAT on your host** under the name `AMSC_TOKEN`, as MAG's guide describes.

=== "macOS / Linux"

    Add this line to `~/.zshrc` (macOS) or `~/.bashrc` (Linux), then open a new terminal:

    ```bash
    export AMSC_TOKEN=<your PAT>
    ```

=== "Windows"

    Set it once as a user variable, then open a new terminal:

    ```powershell
    [Environment]::SetEnvironmentVariable('AMSC_TOKEN', '<your PAT>', 'User')
    ```

PATs are short-lived. When MAG answers `401 Unauthorized`, generate a new PAT on
[myAmSC](https://my.amsc.energy.gov/dashboard), replace the value, open a new terminal and restart the container.

**2. Start Claude Code with `claude-amsc`.** Inside the container, `claude-amsc` runs Claude Code with the
settings MAG recommends for [Claude Code](https://docs.amsc.energy.gov/client-applications/coding-tools/claude-code).
Plain `claude` keeps your normal login.

```bash
cd my-project
/path/to/run.sh claude-amsc          # or: start a shell with /path/to/run.sh, then run claude-amsc
claude-amsc --model claude-haiku     # any claude option works
```

To change a default, set the variable on your host before starting the container, for example
`CLAUDE_CODE_AUTO_COMPACT_WINDOW=100000` for Haiku, or `ANTHROPIC_CUSTOM_HEADERS="X-AmSC-MAG-Provider: amazon"`
to choose the provider. Check access inside the container:

```bash
curl -s -H "Authorization: Bearer $AMSC_TOKEN" https://mag.genesis.americansciencecloud.org/v1/models | head -c 300
```

**3. Codex and OpenCode** read `AMSC_TOKEN` directly, so they only need a provider in their configuration.
Create it once inside the container. It is saved in the `~/.codex` and `~/.config/opencode` volumes, and
holds the variable name, never the PAT.

- **Codex:** add MAG's provider block to `~/.codex/config.toml`
  ([MAG Codex page](https://docs.amsc.energy.gov/client-applications/coding-tools/codex)):

    ```toml
    model = "gpt-6-luna"
    model_provider = "mag"

    [model_providers.mag]
    name = "AmSC MAG"
    base_url = "https://mag.genesis.americansciencecloud.org/v1"
    env_key = "AMSC_TOKEN"
    wire_api = "responses"
    supports_websockets = false
    http_headers = { "X-AmSC-MAG-Provider" = "openai" }
    ```

- **OpenCode:** copy the `amsc-mag` provider from the
  [MAG OpenCode page](https://docs.amsc.energy.gov/client-applications/coding-tools/opencode) into
  `~/.config/opencode/opencode.json`, then pick a model with `/models`.

### ALCF Inference Endpoints

[ALCF Inference Endpoints](https://docs.alcf.anl.gov/services/inference-endpoints) serve open-weight models
on ALCF hardware. Their access tokens last 48 hours.

**1. Log in once on your host** with the `alcf-tokens` CLI (it needs uv, step 3 of
[Getting started](getting-started.md)):

```bash
uv tool install alcf-tokens
alcf-tokens login inference      # opens a Globus login in your browser
```

From then on the run script calls `alcf-tokens get-token inference` each time it starts and passes a fresh
token as `ALCF_AI_TOKEN`. Tokens refresh on their own; ALCF asks you to log in again every 30 days. Without
`alcf-tokens` on the host, set `ALCF_AI_TOKEN` yourself. A container that runs longer than 48 hours needs a
restart to pick up a new token.

**2. Point an agent at an ALCF endpoint.** The
[ALCF agents page](https://docs.alcf.anl.gov/services/inference-endpoints/agents/) has the current endpoints,
model names and full configurations.

- **OpenCode:** add a provider to `~/.config/opencode/opencode.json` in the container. This example uses
  `gpt-oss-120b` on Sophia:

    ```json
    {
      "$schema": "https://opencode.ai/config.json",
      "provider": {
        "alcf-sophia": {
          "npm": "@ai-sdk/openai-compatible",
          "name": "ALCF Sophia",
          "options": {
            "baseURL": "https://inference-api.alcf.anl.gov/resource_server/sophia/vllm/v1",
            "apiKey": "{env:ALCF_AI_TOKEN}"
          },
          "models": {
            "openai/gpt-oss-120b": { "name": "gpt-oss-120b", "limit": { "context": 65536, "output": 0 } }
          }
        }
      }
    }
    ```

    If you also use MAG, put both providers in the same `provider` object.

- **Claude Code:** run `claude-alcf` in the container. It uses Minerva, which speaks the Anthropic Messages API,
  with the `inkling-bf16` model. Pick another model with `ALCF_CLAUDE_MODEL=<name> claude-alcf`, or another
  endpoint with `ALCF_ANTHROPIC_BASE_URL`; set either on the host to make it the default.

- **Codex** needs a model catalog file; follow the Codex section of the ALCF agents page inside the
  container. `ALCF_AI_TOKEN` is already set there.

### GitHub and git

Your SSH keys and host GitHub login stay outside the container. Inside it, git uses HTTPS with the `gh` login.
SSH remotes such as `git@github.com:org/repo.git` are switched to HTTPS automatically, so a project you cloned
with SSH on the host still pushes from the container.

**Log in once inside the container (recommended).** The login is saved in the `ai-agents-gh` volume, and `git push`
uses it:

```bash
gh auth login        # GitHub.com, HTTPS, then log in with a web browser
gh auth status
```

**Or reuse your host login for one session.** If `gh` is logged in on your host, pass its token in:

=== "macOS / Linux"

    ```bash
    GH_TOKEN=$(gh auth token) /path/to/run.sh
    ```

=== "Windows"

    ```powershell
    $env:GH_TOKEN = gh auth token; C:\path\to\run.ps1
    ```

!!! warning "The agent can use any token you pass in"
    A token gives the agent everything that token allows, including pushing to every repository you can
    write to. For the most control, create a
    [fine-grained personal access token](https://github.com/settings/personal-access-tokens/new) limited to
    the repositories you work on, and log in with it (`gh auth login --with-token`) or pass it as `GH_TOKEN`.

**Commits carry your name.** The run script reads `user.name` and `user.email` from your git configuration on the
host and passes them in, so you do not need to configure git inside the container.

## Tips## Tips

- Commit before you prompt: the container protects your machine, git protects your project.
- Get the newest image with `podman pull ghcr.io/autonomous-scientific-agents/agentic-coding:latest`; the run
  script does not update it on its own. Do this whenever you download a newer run script.
- Use another port with `PORT=8081 /path/to/run.sh code` (PowerShell: `$env:PORT = "8081"` first).
- Reset all saved logins and settings: `podman volume rm ai-agents-claude ai-agents-codex ai-agents-opencode ai-agents-opencode-config ai-agents-code-server ai-agents-gh`.
- On Linux the script makes `dev` use your own user and group ID, so files the agent writes in the project
  belong to you.
- Inside the container you are user `dev` with `sudo`, so `sudo apt-get install …` works; it is gone after the
  container stops. Add permanent tools to the `Dockerfile`.
