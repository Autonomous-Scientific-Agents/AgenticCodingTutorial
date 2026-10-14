# Container with OpenCode, Claude Code and OpenAI Codex CLIs, uv, gh, terminal editors
# (vim, emacs, nano) and VS Code in the browser (code-server).
# Published as ghcr.io/autonomous-scientific-agents/agentic-coding by .github/workflows/container.yml.
FROM node:22-bookworm-slim

LABEL org.opencontainers.image.source="https://github.com/Autonomous-Scientific-Agents/AgenticCodingTutorial" \
    org.opencontainers.image.description="Coding agents (Claude Code, Codex CLI, OpenCode) with uv, gh, vim, emacs and VS Code (code-server)" \
    org.opencontainers.image.licenses="MIT"

ARG CODE_SERVER_VERSION=4.141.0

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl wget ca-certificates ripgrep fd-find jq less procps tree unzip \
    openssh-client tmux sudo locales \
    python3 python3-venv build-essential \
    vim emacs-nox nano \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd \
    && sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen \
    && rm -rf /var/lib/apt/lists/*
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 EDITOR=vim

# GitHub CLI from GitHub's apt repository (Debian's own package is years behind)
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# git talks to GitHub over HTTPS with the gh login (`gh auth login`, or GH_TOKEN from the host).
# SSH remotes (git@github.com:...) are rewritten to HTTPS, since no SSH keys are in the container.
RUN git config --system credential.https://github.com.helper '!gh auth git-credential' \
    && git config --system credential.https://gist.github.com.helper '!gh auth git-credential' \
    && git config --system url.https://github.com/.insteadOf git@github.com:

# uv: Python versions, virtual environments and packages
COPY --from=ghcr.io/astral-sh/uv:0.13.0 /uv /uvx /usr/local/bin/

# VS Code in the browser: `./run.sh code`, then open http://localhost:8080
RUN curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone \
    --prefix=/usr/local --version="${CODE_SERVER_VERSION}"

# Install the three agent CLIs globally
RUN npm install -g \
    @anthropic-ai/claude-code \
    @openai/codex \
    opencode-ai \
    && npm cache clean --force

# claude-amsc and claude-alcf: Claude Code with MAG or ALCF Inference Endpoints settings
COPY bin/ /usr/local/bin/

# Non-root user (Claude Code refuses --dangerously-skip-permissions as root).
# dev takes UID/GID 1000 from the base image's unused node user, so it matches the usual first
# user on a Linux host and can write to the mounted project. entrypoint.sh handles other UIDs.
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh \
    && userdel -r node \
    && groupadd -g 1000 dev && useradd -m -s /bin/bash -u 1000 -g 1000 dev \
    && echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev \
    && mkdir -p /workspace /home/dev/.claude /home/dev/.codex /home/dev/.local/share/opencode \
    /home/dev/.config/opencode /home/dev/.config/gh /home/dev/.local/share/code-server \
    && chown -R dev:dev /workspace /home/dev
USER dev
WORKDIR /workspace
# Keep ~/.claude.json (sign-in, trust decisions, MCP servers) inside the persisted ~/.claude
ENV CLAUDE_CONFIG_DIR=/home/dev/.claude

# Python extension for code-server (Open VSX registry)
RUN code-server --install-extension ms-python.python || true

EXPOSE 8080
ENTRYPOINT ["entrypoint.sh"]
CMD ["bash"]
