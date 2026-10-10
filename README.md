# Agentic Coding Tutorial

Material for **Agentic Coding: Basics and Best Practices for Scientific Teams**, a hands-on session on the
Genesis Mission Platform (Foundations session F5).

**Website:** https://autonomous-scientific-agents.github.io/AgenticCodingTutorial/

The site covers getting started, best practices, a tool cheat sheet (Claude Code, Codex CLI, OpenCode, Cursor,
Kilo Code), choosing a model and a budget, the hands-on lab, and the list of helpers you can ask.

## Official documentation

| Tool | Docs | Source |
|---|---|---|
| Claude Code | [code.claude.com/docs](https://code.claude.com/docs/en/quickstart) · [cost tracking](https://code.claude.com/docs/en/costs) | proprietary |
| Codex CLI | [developers.openai.com/codex](https://developers.openai.com/codex) | [openai/codex](https://github.com/openai/codex) |
| OpenCode | [opencode.ai/docs](https://opencode.ai/docs/) · [agents](https://opencode.ai/docs/agents/) · [rules](https://opencode.ai/docs/rules/) · [skills](https://opencode.ai/docs/skills/) · [permissions](https://opencode.ai/docs/permissions/) | open source |
| Cursor | [cursor.com/docs](https://cursor.com/docs) | proprietary |
| Kilo Code | [kilocode.ai/docs](https://kilocode.ai/docs) | [Kilo-Org/kilocode](https://github.com/Kilo-Org/kilocode) |
| uv (Python projects) | [docs.astral.sh/uv](https://docs.astral.sh/uv/) | [astral-sh/uv](https://github.com/astral-sh/uv) |

## Shared conventions (they work across tools)

- [AGENTS.md](https://agents.md/) — the open format for repository instructions read by most agents.
- [Agent Skills](https://agentskills.io/) — the `SKILL.md` folder format; examples in [anthropics/skills](https://github.com/anthropics/skills).
- [Model Context Protocol](https://modelcontextprotocol.io/) — how agents connect to external tools and data.

## Guides and curated collections

- [Claude Code best practices](https://www.anthropic.com/engineering/claude-code-best-practices) (Anthropic engineering blog).
- [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) — curated commands, hooks, skills and workflows.
- [claude-howto](https://github.com/luongnv89/claude-howto) — worked examples, including memory and `CLAUDE.md`.
- [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) — reusable skills, with setup notes for OpenCode.
- [ccusage](https://github.com/ryoppippi/ccusage) — token and cost reports from local agent logs (`npx ccusage@latest daily`).

## Benchmarks: how to read a leaderboard

| Site | What it measures |
|---|---|
| [SWE-bench Pro (Scale)](https://labs.scale.com/leaderboard/swe_bench_pro) | real issues in maintained repositories; one fixed scaffold for every model |
| [Terminal-Bench](https://www.tbench.ai/) | long, multi-step shell tasks run inside real agents |
| [SWE-rebench](https://swe-rebench.com/) | fresh GitHub issues every month, to limit training-data leakage |
| [SWE-bench-Live](https://swe-bench-live.github.io/) | continuously added tasks in many languages |
| [Vals.ai](https://www.vals.ai/benchmarks) | independent re-runs with cost and time per task |
| [Artificial Analysis](https://artificialanalysis.ai/leaderboards/models) | the same tests on every model, with price and cost per task |

Compare scores only when the harness and the data split are the same.

## DOE and ALCF resources

- [AmSC Model Access Gateway (MAG)](https://docs.amsc.energy.gov/model-access-gateway/) — model access for Genesis Mission teams: account, project, personal access token, and setup for Claude Code and Codex CLI.
- [ALCF Inference Endpoints](https://docs.alcf.anl.gov/services/inference-endpoints) — open-weight models on ALCF hardware, including setup for coding agents; examples in [argonne-lcf/inference-endpoints](https://github.com/argonne-lcf/inference-endpoints).

## Tutorial container

- `ghcr.io/autonomous-scientific-agents/agentic-coding` — Claude Code, Codex CLI, OpenCode, uv, vim, emacs and VS Code
  in the browser. Instructions: [Run in a container](https://autonomous-scientific-agents.github.io/AgenticCodingTutorial/container/)
  (`Dockerfile`, `run.sh` and `.devcontainer/` in this repository).

## Evidence worth reading

- CodeRabbit, [State of AI vs. Human Code Generation](https://www.coderabbit.ai/whitepapers/state-of-AI-vs-human-code-generation-report) (Dec 2025): where agent-written pull requests drew more review findings. A vendor study; read the methodology.

## Run the agents in a container

```bash
docker pull ghcr.io/autonomous-scientific-agents/agentic-coding:latest
cd my-project && /path/to/run.sh      # shell with claude, codex, opencode, uv, vim, emacs
/path/to/run.sh code                  # VS Code in the browser at http://localhost:8080
```

Details: [Run in a container](https://autonomous-scientific-agents.github.io/AgenticCodingTutorial/container/).
The image is rebuilt and pushed to GHCR by `.github/workflows/container.yml` when the `Dockerfile` changes.

## Build the site locally

The site uses [MkDocs Material](https://squidfunk.github.io/mkdocs-material/) and is managed with
[uv](https://docs.astral.sh/uv/).

```bash
uv sync
uv run mkdocs serve      # http://127.0.0.1:8000
```

Every push to `main` rebuilds and publishes the site with GitHub Actions (`.github/workflows/pages.yml`).

## Contributing

Helpers and attendees are welcome to contribute: fix a link, add a resource, or add the tools and topics you
can help with. See [CONTRIBUTING.md](CONTRIBUTING.md).
