# Container with OpenCode, Claude Code and OpenAI Codex CLIs, uv, terminal editors
# (vim, emacs, nano) and VS Code in the browser (code-server).
# Published as ghcr.io/autonomous-scientific-agents/agentic-coding by .github/workflows/container.yml.
FROM node:22-bookworm-slim

LABEL org.opencontainers.image.source="https://github.com/Autonomous-Scientific-Agents/AgenticCodingTutorial" \
      org.opencontainers.image.description="Coding agents (Claude Code, Codex CLI, OpenCode) with uv, vim, emacs and VS Code (code-server)" \
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

# Non-root user (Claude Code refuses --dangerously-skip-permissions as root)
RUN useradd -m -s /bin/bash dev \
    && echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev \
    && mkdir -p /workspace /home/dev/.claude /home/dev/.codex /home/dev/.local/share/opencode \
                /home/dev/.local/share/code-server \
    && chown -R dev:dev /workspace /home/dev
USER dev
WORKDIR /workspace

# Python extension for code-server (Open VSX registry)
RUN code-server --install-extension ms-python.python || true

EXPOSE 8080
CMD ["bash"]
