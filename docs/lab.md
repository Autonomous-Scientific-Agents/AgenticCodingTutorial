# Hands-on lab: the point-group classifier

Build a Python package that reads a molecule's XYZ file and returns its Schoenflies point group
(`H2O_C2v.xyz` → `C2v`). The specification is a single `AGENTS.md`; the acceptance tests are the XYZ files in
`core_xyz/`, from H₂ to ferrocene, B₁₂H₁₂ (Ih) and cubane (Oh). The package must get every one right using only
the coordinates, without hard-coding filenames or formulas.

## Demo repositories

Both packages were built from the same specification by different agents. Each has a web app where you can load
a molecule and see its point group and symmetry elements in 3D, and a replay of the agent session that wrote the
code: every prompt, tool call, failed attempt and fix.

| Repository | Built with | Web app (3D) | Agent trace replay |
|---|---|---|---|
| [keceli/claude-pgmol](https://github.com/keceli/claude-pgmol) | Claude Code (Claude Opus 5) | [keceli.github.io/claude-pgmol](https://keceli.github.io/claude-pgmol/) | [traces](https://keceli.github.io/claude-pgmol/traces/) |
| [Autonomous-Scientific-Agents/PGMol](https://github.com/Autonomous-Scientific-Agents/PGMol) | OpenCode (GPT-5.6 Sol) | [PGMol app](https://autonomous-scientific-agents.github.io/PGMol/) | [traces](https://autonomous-scientific-agents.github.io/PGMol/agent-traces/) |

Watch a replay before you start: it shows what working with an agent really looks like, including the dead ends.
The replays were published with the `publish-agent-trace` skill and
[claude-replay](https://github.com/Autonomous-Scientific-Agents/claude-replay); see [Skills and MCP](skills-mcp.md).

## Steps

```bash
git clone https://github.com/keceli/claude-pgmol.git
cd claude-pgmol
git switch -c my-try a6ff35f   # first commit: only AGENTS.md and core_xyz/
/path/to/run.sh            # optional: work inside the tutorial container
claude                     # or codex, opencode
```

| Step | You do | Checkpoint |
|---|---|---|
| 1 | Read `AGENTS.md` yourself first. What is the goal, what are the limits, how is success checked? | you can state the success criterion |
| 2 | Ask the agent for a plan before any code. Approve or correct it. | a plan you agree with |
| 3 | Let it build, one step per prompt. Read every diff; commit each green step. | all `core_xyz/` fixtures pass |
| 4 | Verify the verifier: try rotated and shuffled copies of a molecule, and a few `challenge_xyz/` files from `main`. | failures you understand |
| 5 | Review with a second tool or model; ask it to find defects, then fix them with tests. | review findings fixed |
| 6 | Stretch: profile on a large molecule and speed it up, or add a small GUI, keeping the tests green. | before/after numbers, or an app |

Compare your result with `main` of claude-pgmol and with PGMol: same specification, different agents, different
code. To split the work across sessions, see [Working with multiple agents](muiltiagents.md).
