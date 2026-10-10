# Getting started

> *Başlamak bitirmenin yarısıdır* — starting is half of finishing (Turkish).
> Plato quotes it as a proverb, *ἀρχὴ ἥμισυ παντός*; Aristotle says the beginning is *more* than half.
> Horace: *Dimidium facti qui coepit habet*. English: *well begun is half done*. Korean: *시작이 반이다*.

The choice of tool matters less than starting. All of them run the same loop and read the same kinds of files,
and those files live in your repository, so switching later costs nothing.

## Your first hour

1. **Pick one tool and install it.** Any of the five. If your site provides model access, start with a tool
   that supports it.
2. **Let it draft `AGENTS.md`.** `/init` writes a first version from your repository, or draft it with a chat
   assistant. Cut it to under 60 lines: commands, rules, no-go zones.
3. **Start small and checkable.** A test, a docstring with units, a plot — on a real repository, with a commit
   before you prompt.
4. **Review the diff, commit, repeat.** One step per prompt.

## Install

```bash
# Claude Code
curl -fsSL https://claude.ai/install.sh | bash

# OpenCode
curl -fsSL https://opencode.ai/install | bash

# Codex CLI
npm install -g @openai/codex

# uv, for Python projects
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Cursor is a desktop application ([cursor.com](https://cursor.com)); Kilo Code is an extension for VS Code and
JetBrains IDEs ([kilocode.ai](https://kilocode.ai)). Check each tool's documentation for other installers.

!!! tip "Using DOE or ALCF model endpoints"
    The [ALCF Inference Endpoints documentation](https://docs.alcf.anl.gov/services/inference-endpoints)
    describes how to point coding agents at open-weight models hosted on ALCF hardware.
