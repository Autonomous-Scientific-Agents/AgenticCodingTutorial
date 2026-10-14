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

The run script uses `docker` when it is installed and `podman` otherwise. If you have both, choose with
`CONTAINER_ENGINE=podman` (PowerShell: `$env:CONTAINER_ENGINE = "podman"`).

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

The script passes these variables from your shell into the container when they are set:
`ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_BASE_URL`, `OPENAI_API_KEY`, `OPENAI_BASE_URL`,
`OPENROUTER_API_KEY`.

- **Subscription login:** run `claude` or `codex` and follow the login prompt. Logins and settings are stored in
  named volumes, so you sign in once. That covers `~/.claude` (including `.claude.json`: sign-in, trusted
  folders and MCP servers), `~/.codex`, and OpenCode's `~/.config/opencode` and `~/.local/share/opencode`.
- **GitHub CLI:** run `gh auth login` in the container to open pull requests and issues with `gh`. This sign-in
  is not stored in a volume, so repeat it when you start a new container.
- **Genesis Mission teams:** the [AmSC Model Access Gateway (MAG)](https://docs.amsc.energy.gov/model-access-gateway/)
  explains how to get access and a personal access token, and how to point Claude Code and Codex at it.
  Set the variables it describes on your host before starting the container.

## Tips

- Commit before you prompt: the container protects your machine, git protects your project.
- Get the newest image with `podman pull ghcr.io/autonomous-scientific-agents/agentic-coding:latest`; the run
  script does not update it on its own. Do this whenever you download a newer run script.
- Use another port with `PORT=8081 /path/to/run.sh code` (PowerShell: `$env:PORT = "8081"` first).
- Reset all saved logins and settings: `podman volume rm ai-agents-claude ai-agents-codex ai-agents-opencode ai-agents-opencode-config ai-agents-code-server`.
- On Linux the script makes `dev` use your own user and group ID, so files the agent writes in the project
  belong to you.
- Inside the container you are user `dev` with `sudo`, so `sudo apt-get install …` works; it is gone after the
  container stops. Add permanent tools to the `Dockerfile`.
