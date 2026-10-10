# Tools cheat sheet

Five tools, one pattern. Paths and features change monthly; check `/help` in the version you install.

| | Claude Code | OpenCode | Codex CLI | Cursor | Kilo Code |
|---|---|---|---|---|---|
| Surface | terminal, VS Code, desktop, web | terminal TUI, VS Code | terminal, VS Code, web | IDE (VS Code fork) + CLI | VS Code / JetBrains extension + CLI |
| Models | Anthropic | any provider, incl. local | OpenAI | several, routed | hundreds, bring your own key / local |
| Instructions | `CLAUDE.md` (+ `.claude/rules/`) | `AGENTS.md` (reads `CLAUDE.md` too) | `AGENTS.md` (+ `~/.codex/`) | `.cursor/rules/*.mdc` | rules + Memory Bank |
| Skills | `.claude/skills/*/SKILL.md` | `.opencode/skills`, `.claude/skills`, `.agents/skills` | `.codex/skills`, `.agents/skills` | own format | custom modes |
| Memory | auto-memory `MEMORY.md` + `/memory` | `AGENTS.md` + session | `AGENTS.md` + session | codebase index | Memory Bank (Markdown in repo) |
| Enforcement | hooks + permission rules | allow / ask / deny config | sandbox + approval modes | rules only | rules only |
| Licence | proprietary | open source | open source (CLI) | proprietary | open source (MIT) |

## Same move, three keystrokes

| Move | Claude Code | Codex CLI | OpenCode |
|---|---|---|---|
| Draft the instructions file | `/init → CLAUDE.md` | `/init → AGENTS.md` | `/init → AGENTS.md` |
| Read-only planning | `Shift+Tab → plan mode` | `/plan` | `Tab → Plan agent` |
| Undo the agent's changes | `Esc Esc → /rewind (code, chat or both)` | `git; inspect with /diff` | `/undo, /redo (git-backed)` |
| Free up context | `/compact <what to keep>, /clear` | `/compact, /new` | `/compact, /new` |
| Shell output into context | `!uv run pytest -x` | `!uv run pytest -x` | `!uv run pytest -x` |
| Attach a file | `@path` | `@path or /mention path` | `@path` |
| Reusable procedure | `.claude/skills/x/SKILL.md → /x` | `.agents/skills/x/SKILL.md → $x` | `.opencode/commands/x.md → /x` |
| Pick up yesterday's session | `claude -c, /resume` | `codex resume, /resume, /fork` | `opencode -c, /sessions` |
| Headless / CI | `claude -p "…"` | `codex exec "…"` | `opencode run "…"` |
| No prompts at all (sandbox only) | `--dangerously-skip-permissions` | `--yolo  (or -a never -s workspace-write)` | `--auto  (deny rules still apply)` |

!!! warning "No-prompt modes"
    Run without approval prompts only inside a sandbox, container or scratch clone — never on a shared
    allocation or production data.
