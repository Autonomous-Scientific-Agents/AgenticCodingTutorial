# Run the agents in a container

The tutorial container has everything you need for the session:
Claude Code, Codex CLI and OpenCode, plus [uv](https://docs.astral.sh/uv/), git, Python 3, the terminal
editors vim, emacs and nano, and VS Code in the browser ([code-server](https://github.com/coder/code-server)).

!!! success "Why a container is a safe place for an agent"
    The agent can only see the project folder you mount into it. It cannot read your home directory,
    SSH keys, or other projects, and anything it installs disappears when the container stops.
    Your work in the mounted folder is kept, so commit it with git as usual.
    Inside a container it is reasonable to allow more autonomy (fewer approval prompts) than on your laptop
    or on a shared allocation.

Image: `ghcr.io/autonomous-scientific-agents/agentic-coding:latest` (Linux amd64 and arm64, so it runs on
Intel and Apple-silicon machines).

## 1. Install Docker

Install [Docker Desktop](https://docs.docker.com/get-started/get-docker/) (macOS, Windows) or Docker Engine
(Linux). [Podman](https://podman.io/) also works: replace `docker` with `podman` below.

## 2. Get the image and the run script

```bash
docker pull ghcr.io/autonomous-scientific-agents/agentic-coding:latest
curl -fsSLO https://raw.githubusercontent.com/Autonomous-Scientific-Agents/AgenticCodingTutorial/main/run.sh
chmod +x run.sh
```

Prefer to build it yourself? Clone this repository and run `./run.sh build`.

## 3. Start it in your project

Run the script **from the project folder** you want the agent to work on. That folder appears as
`/workspace` inside the container, and nothing else from your machine does.

```bash
cd my-project
/path/to/run.sh            # a bash shell inside the container
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
  named Docker volumes, so you sign in once.
- **Genesis Mission teams:** the [AmSC Model Access Gateway (MAG)](https://docs.amsc.energy.gov/model-access-gateway/)
  explains how to get access and a personal access token, and how to point Claude Code and Codex at it.
  Set the variables it describes on your host before starting the container.

## Tips

- Commit before you prompt: the container protects your machine, git protects your project.
- Use another port with `PORT=8081 /path/to/run.sh code`.
- Reset all saved logins and settings: `docker volume rm ai-agents-claude ai-agents-codex ai-agents-opencode ai-agents-code-server`.
- Inside the container you are user `dev` with `sudo`, so `sudo apt-get install …` works; it is gone after the
  container stops. Add permanent tools to the `Dockerfile`.
