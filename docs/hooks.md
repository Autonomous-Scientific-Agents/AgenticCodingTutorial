# Hooks

A hook is a command that the agent tool runs at a fixed point: before a tool call, after a file edit, when the
agent stops. The model does not decide whether a hook runs. That makes hooks the right place for rules that must
always hold, such as formatting every edited file or refusing a dangerous command. Instructions in `AGENTS.md`
are only requests; the model can forget them in a long session.

| Use a | When |
|---|---|
| Instruction (`AGENTS.md`) | a rule the agent should usually follow |
| [Skill](skills.md) | a procedure for one kind of task |
| [MCP server](mcp.md) | a tool the agent cannot get otherwise |
| Hook | something that must happen every time, without the model's choice |

## Claude Code

Hooks live in a settings file:

| File | Applies to |
|---|---|
| `~/.claude/settings.json` | all your projects |
| `.claude/settings.json` | this project; commit it to share with your team |
| `.claude/settings.local.json` | this project, only for you (not committed) |

Each hook names an **event**, an optional **matcher** (a tool name, or several joined with `|`) and a
**command**. The command receives the event as JSON on standard input; for tool events, `tool_input` holds the
tool's arguments. Run `/hooks` in Claude Code to see which hooks are active and where each is defined.

The most useful events:

| Event | Runs | Typical use |
|---|---|---|
| `PreToolUse` | before a tool call; can block it | refuse dangerous commands, protect files |
| `PostToolUse` | after a tool call succeeds | format or lint the edited file, run fast tests |
| `UserPromptSubmit` | when you send a prompt | add context, such as the current branch |
| `Stop` | when the agent finishes its answer | notify you, run a final check |
| `SessionStart` | when a session starts or resumes | load project state |
| `Notification` | when Claude Code needs your attention | desktop or chat notification |

The [hooks reference](https://code.claude.com/docs/en/hooks) lists every event and field.

**Exit codes.** `0` means continue. `2` blocks the action (for events that can block, such as `PreToolUse`) and
sends the command's standard error back to the agent as the reason, so it can adjust. Any other code is reported as
a hook error and the action goes ahead.

### Example: format every edited Python file

Add to `.claude/settings.json` (needs `jq` and [ruff](https://docs.astral.sh/ruff/)):

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "f=$(jq -r '.tool_input.file_path'); case \"$f\" in *.py) ruff format \"$f\" ;; esac"
          }
        ]
      }
    ]
  }
}
```

### Example: block `rm -rf`

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "c=$(jq -r '.tool_input.command'); case \"$c\" in *'rm -rf'*) echo 'Blocked by hook: rm -rf is not allowed here' >&2; exit 2 ;; esac"
          }
        ]
      }
    ]
  }
}
```

The agent sees the message and can choose another way, such as removing a single file. A text match like this is
easy to get around (`rm -r -f`, a script that deletes files), so treat it as a guard against mistakes, not as
security. For real limits, use [permissions](best-practices.md) and the [container](container.md).

To use both examples, merge them into one `"hooks"` object in the same file. For longer logic, put the command in
a script, such as `.claude/hooks/format.sh`, and point `command` at it.

## Other tools

- **Codex CLI** has hooks in the same JSON shape and with mostly the same event names (`PreToolUse`,
  `PostToolUse`, `UserPromptSubmit`, `Stop`, `SessionStart` and more). They go in `~/.codex/hooks.json` or a
  project's `.codex/hooks.json`, or in `config.toml`. Codex runs a hook only after you have reviewed and trusted it
  with `/hooks`. See the [Codex hooks documentation](https://developers.openai.com/codex/hooks).
- **OpenCode** uses plugins: JavaScript or TypeScript files in `.opencode/plugins/` (project) or
  `~/.config/opencode/plugins/` (global) that subscribe to events such as `tool.execute.before`,
  `tool.execute.after` and `session.idle`. See [OpenCode plugins](https://opencode.ai/docs/plugins/).
- **Cursor** reads hooks from `.cursor/hooks.json`. Its event names and format differ; see the Cursor documentation.

## Use hooks with care

- A hook runs with your user's permissions, every time its event fires, with no confirmation. Read the hooks in a
  repository you clone before you start an agent there: `.claude/settings.json` can contain them.
- Keep hooks fast. A slow `PostToolUse` hook slows down every edit; run the full test suite at `Stop` or in CI
  instead.
- Start with one hook, check it with `/hooks`, and add more once it works.
