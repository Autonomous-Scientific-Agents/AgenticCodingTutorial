# Skills and MCP servers

Two ways to give an agent new abilities. Both work across Claude Code, Codex CLI, OpenCode and Cursor.

| | Skill | MCP server |
|---|---|---|
| What it is | a procedure you write once: a folder with `SKILL.md` (and optional scripts) | a program that exposes tools and data the agent can call |
| In context | name and description always; the body only when the task matches or you call it | every tool definition, on every turn |
| Use it for | how *you* want a task done: benchmarking, releasing, publishing a trace | things the agent cannot do alone: current docs, a browser, GitHub, a simulation code, an HPC facility |

## Skills

A skill is a folder with a `SKILL.md` file:

```markdown
---
name: benchmark
description: Measure performance before and after a change. Use when asked to profile, optimize or speed up code.
---

1. Run the baseline: `uv run python bench/run.py --label before`.
2. Profile the slow case, change one thing, keep the tests green.
3. Re-measure and report a before/after table.
```

The `description` decides when the agent loads the skill, so say *when to use it*, not only what it does.

| Tool | Where skills live | Call one by name |
|---|---|---|
| Claude Code | `.claude/skills/<name>/SKILL.md`, `~/.claude/skills/` | `/name` |
| Codex CLI | `.agents/skills/`, `~/.agents/skills/` | `$name` |
| OpenCode | `.opencode/skills/`, also reads `.claude/skills/` and `.agents/skills/` | `/name` |
| Cursor | `.cursor/skills/`, also reads `.agents/skills/`, `.claude/skills/` | `/name` |

Paths change between versions; check your tool's documentation. Keeping skills in `.agents/skills/` (with a
`.claude/skills` link for Claude Code) gives one copy for every tool.

**Example from this session:** the demo replays were made with a `publish-agent-trace` skill. It archives a
sanitized copy of the agent session in the repository and builds an HTML replay with
[claude-replay](https://github.com/Autonomous-Scientific-Agents/claude-replay), so others can see how the code was written.

### Where to find skills

- [anthropics/skills](https://github.com/anthropics/skills): Anthropic's examples, including document and design skills.
- [openai/skills](https://github.com/openai/skills): skills for Codex.
- [K-Dense-AI/claude-scientific-skills](https://github.com/K-Dense-AI/claude-scientific-skills): a large collection for scientific work (bioinformatics, chemistry, data analysis).
- [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills): engineering skills, with setup notes for several tools.
- [vercel-labs/skills](https://github.com/vercel-labs/skills): a CLI that installs skills into any of the supported agents.
- [agentskills.io](https://agentskills.io/): the open `SKILL.md` format.

Read a skill before you install it: it is instructions the agent will follow, and it can include scripts.

## MCP servers

The [Model Context Protocol](https://modelcontextprotocol.io/) connects agents to tools. A server is either
**local** (a command the agent starts) or **remote** (a URL).

### Add a server

```bash
# Claude Code
claude mcp add context7 -- npx -y @upstash/context7-mcp

# Codex CLI (writes ~/.codex/config.toml)
codex mcp add context7 -- npx -y @upstash/context7-mcp
```

```json
// OpenCode: opencode.json
{
  "mcp": {
    "context7": { "type": "local", "command": ["npx", "-y", "@upstash/context7-mcp"] }
  }
}
```

Cursor reads `.cursor/mcp.json` (project) or `~/.cursor/mcp.json`. Use `/mcp` in Claude Code and OpenCode, or
`codex mcp list`, to see what is connected.

### Useful servers

| Server | What it gives the agent |
|---|---|
| [Context7](https://github.com/upstash/context7) | current documentation for libraries, so the agent does not rely on stale training data |
| [Playwright MCP](https://github.com/microsoft/playwright-mcp) | a browser: test the web app it just built, read pages |
| [GitHub MCP server](https://github.com/github/github-mcp-server) | issues, pull requests, code search, Actions |
| [Reference servers](https://github.com/modelcontextprotocol/servers) | filesystem, git, fetch, memory and more |
| [ChemGraph](https://github.com/argonne-lcf/ChemGraph) | computational chemistry workflows (structures, ASE, xTB, MACE and more): `python -m chemgraph.mcp.mcp_tools` |
| [amsc_agentic_ai](https://github.com/zhenghh04/amsc_agentic_ai) | examples of agents and MCP servers for DOE facilities (IRI APIs at ALCF, NERSC, OLCF) |

Find more in the [MCP Registry](https://registry.modelcontextprotocol.io/) and
[awesome-mcp-servers](https://github.com/punkpeye/awesome-mcp-servers).

!!! warning "Use MCP servers with care"
    - Every tool definition is loaded on every turn. Disconnect servers you are not using.
    - Tool output is untrusted input: a web page or an issue can contain instructions aimed at the agent.
    - A server runs with your credentials. Install only servers you trust, give tokens the narrowest scope,
      and prefer running agents with MCP access inside the [container](container.md).
