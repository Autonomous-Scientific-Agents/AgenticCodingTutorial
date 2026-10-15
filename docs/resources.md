# Resources

## Official documentation

| Tool | Docs | Source |
|---|---|---|
| Claude Code | [code.claude.com/docs](https://code.claude.com/docs/en/quickstart) · [cost tracking](https://code.claude.com/docs/en/costs) | proprietary |
| Codex CLI | [developers.openai.com/codex](https://developers.openai.com/codex) | [openai/codex](https://github.com/openai/codex) |
| OpenCode | [opencode.ai/docs](https://opencode.ai/docs/) · [agents](https://opencode.ai/docs/agents/) · [rules](https://opencode.ai/docs/rules/) · [skills](https://opencode.ai/docs/skills/) · [permissions](https://opencode.ai/docs/permissions/) | open source |
| OpenCode 2 | [opencode.ai/v2/docs](https://opencode.ai/v2/docs) | open source |
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

## Skills, MCP servers and hooks

- [Genesis Skills](https://gitlab.osti.gov/genesis/genesis-skills) — Genesis Mission skills for science and engineering (HPC, AmSC, literature, plasma simulation, data and evaluation); upstream on [GitHub](https://github.com/AI-ModCon/genesis-skills).
- [anthropics/skills](https://github.com/anthropics/skills) · [openai/skills](https://github.com/openai/skills) · [K-Dense-AI/claude-scientific-skills](https://github.com/K-Dense-AI/claude-scientific-skills) — skill collections.
- [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers) · [MCP Registry](https://registry.modelcontextprotocol.io/) · [awesome-mcp-servers](https://github.com/punkpeye/awesome-mcp-servers) — MCP servers.
- [Claude Code hooks](https://code.claude.com/docs/en/hooks) · [Codex hooks](https://developers.openai.com/codex/hooks) · [OpenCode plugins](https://opencode.ai/docs/plugins/) — hooks that run commands at fixed points.
- [ChemGraph](https://github.com/argonne-lcf/ChemGraph) — computational chemistry agent with an MCP server.
- [AtomisticSkills](https://github.com/learningmatter-mit/AtomisticSkills) — computational chemistry skills.
- [claude-replay](https://github.com/Autonomous-Scientific-Agents/claude-replay) — turn an agent session into an HTML replay.
- [ai4s-skills](https://github.com/ai4s-research/ai4s-skills) — skill collection for AI-for-science work.
- [claude-scholar](https://github.com/Galaxy-Dawn/claude-scholar) — skill collection for research.
- More, with setup for each tool: [Skills](skills.md), [MCP servers](mcp.md) and [Hooks](hooks.md).

## Benchmarks: how to read a leaderboard

| Site | What it measures |
|---|---|
| [SWE-bench Pro (Scale)](https://labs.scale.com/leaderboard/swe_bench_pro) | real issues in maintained repositories; one fixed scaffold for every model |
| [Terminal-Bench](https://www.tbench.ai/) | long, multi-step shell tasks run inside real agents |
| [SWE-rebench](https://swe-rebench.com/) | fresh GitHub issues every month, to limit training-data leakage |
| [SWE-bench-Live](https://swe-bench-live.github.io/) | continuously added tasks in many languages |
| [Vals.ai](https://www.vals.ai/benchmarks) | independent re-runs with cost and time per task |
| [Artificial Analysis](https://artificialanalysis.ai/leaderboards/models) | the same tests on every model, with price and cost per task |
| [ResearchClawBench](https://internscience.github.io/ResearchClawBench-Home/) | end-to-end automated research tasks (chemistry, physics and more) |

Compare scores only when the harness and the data split are the same.

## DOE and ALCF resources

- [AmSC Model Access Gateway (MAG)](https://docs.amsc.energy.gov/model-access-gateway/) — model access for Genesis Mission teams: account, project, personal access token, and setup for Claude Code and Codex CLI.
- [argo-proxy](https://github.com/oaklight/argo-proxy) — multi-format gateway to ARGO for ANL-internal users; translates OpenAI, Anthropic, and Google GenAI formats.
- [argo-shim](https://github.com/n-getty/argo-shim) — lightweight HTTP proxy + SSH tunnel for Claude Code and Codex CLI on ALCF machines.
- [ALCF Inference Endpoints](https://docs.alcf.anl.gov/services/inference-endpoints) — open-weight models on ALCF hardware (Sophia, Metis, Minerva); Globus auth; web UI and API access.
- [Custom endpoints guide](endpoints.md) — setup walkthrough for argo-proxy, argo-shim, and ALCF Inference with multiple tools.

## Tutorial container

- `ghcr.io/autonomous-scientific-agents/agentic-coding` — Claude Code, Codex CLI, OpenCode, uv, gh, vim, emacs and VS Code
  in the browser. Instructions: [Run in a container](container.md)
  (`Dockerfile`, `run.sh` and `.devcontainer/` in this repository).

## Evidence worth reading

- CodeRabbit, [State of AI vs. Human Code Generation](https://www.coderabbit.ai/whitepapers/state-of-AI-vs-human-code-generation-report) (Dec 2025): where agent-written pull requests drew more review findings. A vendor study; read the methodology.
