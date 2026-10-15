# MCP servers

The [Model Context Protocol](https://modelcontextprotocol.io/) (MCP) connects agents to tools and data they
cannot reach on their own: current documentation, a browser, GitHub, a simulation code, an HPC facility. MCP works
across Claude Code, Codex CLI, OpenCode and Cursor. To give the agent a procedure instead of a tool, write a
[skill](skills.md).

A server is either **local** (a command the agent starts) or **remote** (a URL).

## Add a server

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

## Useful servers

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
