# Skills

A skill is a procedure you write once and the agent follows when the task calls for it. Skills work across
Claude Code, Codex CLI, OpenCode and Cursor. Two related ways to extend an agent have their own pages:
[MCP servers](mcp.md) add tools, and [hooks](hooks.md) run your commands automatically.

| | Skill | MCP server | Hook |
|---|---|---|---|
| What it is | a folder with `SKILL.md` (and optional scripts) | a program that exposes tools and data the agent can call | a command the agent tool runs at a fixed point, such as after every edit |
| Who decides when it runs | the agent, when the task matches the description (or you, by name) | the agent, when it calls a tool | the tool itself, every time, whatever the model decides |
| In context | name and description always; the body only when used | every tool definition, on every turn | nothing, unless the hook returns output |
| Use it for | how *you* want a task done: benchmarking, releasing, publishing a trace | things the agent cannot do alone: current docs, a browser, GitHub, a simulation code, an HPC facility | rules that must always hold: format after edits, block dangerous commands, notify when done |

## Write a skill

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

## Where to find skills

- [Genesis Skills](https://gitlab.osti.gov/genesis/genesis-skills): the Genesis Mission collection of skills for
  science and engineering, including HPC, AmSC, literature search, plasma simulation, scientific-data metadata
  and AI-system evaluation. It works with Claude Code, Codex, Cursor, OpenCode and Gemini CLI. Development, issues
  and pull requests happen on the [GitHub upstream](https://github.com/AI-ModCon/genesis-skills); see below to
  install it.
- [anthropics/skills](https://github.com/anthropics/skills): Anthropic's examples, including document and design skills.
- [openai/skills](https://github.com/openai/skills): skills for Codex.
- [K-Dense-AI/claude-scientific-skills](https://github.com/K-Dense-AI/claude-scientific-skills): a large collection for scientific work (bioinformatics, chemistry, data analysis).
- [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills): engineering skills, with setup notes for several tools.
- [vercel-labs/skills](https://github.com/vercel-labs/skills): a CLI that installs skills into any of the supported agents.
- [agentskills.io](https://agentskills.io/): the open `SKILL.md` format.

### Install Genesis Skills

The repository groups skills by domain (`skills/<domain>/<skill>/`). Agents expect each skill directly in their
skills folder, so its `unpack.sh` script copies them there:

```bash
git clone https://gitlab.osti.gov/genesis/genesis-skills.git
cd genesis-skills
./unpack.sh --list                                          # preview the skills
./unpack.sh --target ~/.claude/skills --mode copy           # Claude Code
./unpack.sh --target ~/.agents/skills --mode copy           # Codex, Cursor, OpenCode, Gemini CLI
```

Add a domain name, such as `./unpack.sh hpc-skills --target ...`, to install one domain only. Use
`--mode symlink` to keep the skills linked to the clone, so that `git pull` updates them. Skills with the same
name already in the target folder are replaced. See the
[repository README](https://gitlab.osti.gov/genesis/genesis-skills) for details.

Read a skill before you install it: it is instructions the agent will follow, and it can include scripts.
