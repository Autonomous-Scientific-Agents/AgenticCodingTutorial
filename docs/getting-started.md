# Getting started

> *Başlamak bitirmenin yarısıdır*: starting is half of finishing (Turkish).
> Plato quotes it as a proverb, *ἀρχὴ ἥμισυ παντός*; Aristotle says the beginning is *more* than half.
> Horace: *Dimidium facti qui coepit habet*. English: *well begun is half done*. Korean: *시작이 반이다*.

The choice of tool matters less than starting. All of them run the same loop and read the same kinds of files,
and those files live in your repository, so switching later costs nothing.

## Your first hour

1. **Pick one tool and install it.** Any of the five. If your site provides model access, start with a tool
   that supports it.
2. **Say what you want, and how you will check it.** This is where careful thought pays off most. Before you
   prompt, decide the goal, the limits (what must not change, which dependencies are allowed) and the check that
   proves it worked: a test, a known value, a reference result, a plot you know how to read. Put all of that in the
   prompt. If you find yourself repeating the same instructions, move them into `AGENTS.md`; it helps you be
   specific, but you do not need one to start.
3. **Start small and checkable.** A test, a docstring with units, a plot, on a real repository, with a commit
   before you prompt.
4. **Review the diff, commit, repeat.** One step per prompt.

## Install, step by step

These steps assume a fresh computer with nothing installed. Follow the tab for your operating system. Each step
ends with a check; if the check works, move on.

!!! tip "Easiest and safest: the tutorial container"
    One image has Claude Code, Codex CLI, OpenCode, uv, gh, vim, emacs and VS Code in the browser. The agent only sees
    the project folder you mount, so it cannot touch the rest of your machine. You only need Git (step 2) and Docker.
    See [Run in a container](container.md).

### What you need

- **A computer:** Windows 10 (version 1809 or later) or Windows 11, 64-bit; macOS 13 or later; or a recent Linux.
- **Model access:** a subscription or API key for the tool you pick (Claude for Claude Code, ChatGPT or OpenAI
  for Codex, any provider for OpenCode), or access through [MAG](#model-access) for Genesis Mission teams.
- **About 30 minutes** and permission to install software. Most steps below do not need administrator rights;
  Git and Docker Desktop may ask for them.

### 1. Open a terminal

A terminal is a window where you type commands. Every command on this page is typed (or pasted) there,
followed by Enter.

=== "Windows"

    Press ++win+x++ and choose **Terminal** (Windows 11) or **Windows PowerShell** (Windows 10).
    Check that you are in PowerShell: the prompt starts with `PS C:\`.

    Use PowerShell, not "Command Prompt" (`cmd`): the commands below are PowerShell commands.

=== "macOS"

    Press ++cmd+space++, type **Terminal**, and press Enter.

=== "Linux"

    Open your distribution's terminal (often ++ctrl+alt+t++).

!!! note "After installing something, open a new terminal"
    A terminal reads the list of installed programs (the `PATH`) when it starts. If a check below says
    *"not recognized"* or *"command not found"* right after an install, close the terminal, open a new one and
    try again. This fixes most problems.

### 2. Install Git

Git keeps the history of your project, and it is your undo button when an agent makes a change you do not want.

=== "Windows"

    ```powershell
    winget install --id Git.Git -e
    ```

    If `winget` is not available, download the installer from
    [git-scm.com/downloads/win](https://git-scm.com/downloads/win) and click **Next** on every screen to keep
    the defaults. Git for Windows also installs **Git Bash**, which Claude Code uses to run commands.

=== "macOS"

    ```bash
    xcode-select --install
    ```

    Click **Install** in the window that opens. This installs Apple's command-line tools, including Git.

=== "Linux"

    ```bash
    sudo apt update && sudo apt install -y git curl     # Ubuntu / Debian
    # sudo dnf install -y git curl                       # Fedora / RHEL
    ```

Open a new terminal, check, and tell Git who you are (once per computer):

```bash
git --version
git config --global user.name "Your Name"
git config --global user.email "you@lab.gov"
```

### 3. Install uv (Python)

[uv](https://docs.astral.sh/uv/) installs Python itself, creates project environments and installs packages.
You do not need a separate Python installation.

=== "Windows"

    ```powershell
    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
    ```

=== "macOS / Linux"

    ```bash
    curl -LsSf https://astral.sh/uv/install.sh | sh
    ```

Open a new terminal, then:

```bash
uv --version
uv python install 3.12
```

### 4. Install Node.js (only if you need it)

The recommended installers below do not need Node.js. You need it only for **OpenCode on Windows** (npm route)
or if you prefer installing any tool with `npm`.

=== "Windows"

    ```powershell
    winget install --id OpenJS.NodeJS.LTS -e
    ```

=== "macOS"

    Download the LTS installer from [nodejs.org](https://nodejs.org/), or with Homebrew: `brew install node`.

=== "Linux"

    Use the LTS release from [nodejs.org](https://nodejs.org/en/download) (the page gives the command for your
    distribution).

Check in a new terminal: `node --version` and `npm --version`.

### 5. Install a coding agent

Pick **one** to start. You can add others later; they read the same files in your repository.
The commands below come from each tool's official page, which is the place to check if anything changes.

#### Claude Code

Official: [github.com/anthropics/claude-code](https://github.com/anthropics/claude-code) ·
[setup documentation](https://code.claude.com/docs/en/setup)

=== "Windows"

    ```powershell
    irm https://claude.ai/install.ps1 | iex
    ```

    Alternative: `winget install Anthropic.ClaudeCode`. Install Git (step 2) first, so Claude Code can use Git Bash.

=== "macOS / Linux"

    ```bash
    curl -fsSL https://claude.ai/install.sh | bash
    ```

    Alternative on macOS: `brew install --cask claude-code`.

Check: `claude --version`. The npm package is deprecated; use the installers above.

#### Codex CLI

Official: [github.com/openai/codex](https://github.com/openai/codex) ·
[documentation](https://developers.openai.com/codex)

=== "Windows"

    ```powershell
    powershell -ExecutionPolicy ByPass -c "irm https://chatgpt.com/codex/install.ps1 | iex"
    ```

=== "macOS / Linux"

    ```bash
    curl -fsSL https://chatgpt.com/codex/install.sh | sh
    ```

Alternatives: `npm install -g @openai/codex` (needs Node.js, step 4) or `brew install --cask codex`.
Check: `codex --version`.

#### OpenCode

Official: [github.com/anomalyco/opencode](https://github.com/anomalyco/opencode) ·
[documentation](https://opencode.ai/docs/)

=== "Windows"

    ```powershell
    npm install -g opencode-ai@latest
    ```

    This needs Node.js (step 4). If you use [Scoop](https://scoop.sh/) or [Chocolatey](https://chocolatey.org/):
    `scoop install opencode` or `choco install opencode`.

=== "macOS / Linux"

    ```bash
    curl -fsSL https://opencode.ai/install | bash
    ```

    Alternative: `brew install anomalyco/tap/opencode`.

Check: `opencode --version`.

#### IDE agents (no terminal needed)

- **Cursor:** download from [cursor.com](https://cursor.com/), install, and sign in. It is a VS Code-based editor
  with an agent built in.
- **Kilo Code:** install [VS Code](https://code.visualstudio.com/) (Windows: `winget install --id Microsoft.VisualStudioCode -e`),
  then search for *Kilo Code* in the Extensions panel. See [kilocode.ai/docs](https://kilocode.ai/docs).
- Claude Code and Codex also have VS Code extensions; search for them in the Extensions panel.

### 6. Sign in and run it the first time

Make a folder for a first project, put it under Git, and start the agent inside it:

```bash
mkdir my-first-agent-project
cd my-first-agent-project
git init
claude        # or: codex, opencode
```

The first run asks you to sign in: a browser window opens for a subscription login, or you can use an API key.
For Genesis Mission model access, see [Model access](#model-access) below. Type `/help` inside the agent to see its
commands, and `/exit` (or ++ctrl+c++ twice) to leave.

Then try the [hands-on lab](lab.md): it starts from a specification and a set of test molecules.

### Windows troubleshooting

| Problem | Fix |
|---|---|
| `'claude' is not recognized` (or `codex`, `uv`, `git`) | Close the terminal and open a new one. If it persists, rerun the installer and read its last lines: it prints the folder to add to your `PATH`. |
| `running scripts is disabled on this system` | Allow scripts for your user once: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`, then open a new terminal. |
| `winget` is not recognized | Install or update **App Installer** from the Microsoft Store, or use the download links above. |
| Commands from a guide use `export VAR=...` | That is bash syntax. In PowerShell write `$env:VAR = "..."` (current window only). |
| You want a Linux environment instead | Run `wsl --install` in an administrator PowerShell, restart, open **Ubuntu** from the Start menu and follow the **Linux** tabs on this page. |
| You want the container | Install [Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/) (it uses WSL 2), then follow [Run in a container](container.md). |

## Model access

The steps above work with any model provider. Genesis Mission teams can get model access through the
[AmSC Model Access Gateway (MAG)](https://docs.amsc.energy.gov/model-access-gateway/), which explains how to
request access, create a personal access token, and connect Claude Code and Codex CLI.

The [ALCF Inference Endpoints documentation](https://docs.alcf.anl.gov/services/inference-endpoints)
describes how to point coding agents at open-weight models hosted on ALCF hardware.
