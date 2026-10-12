# Working with multiple agents

Divide a large task across several agents, run them in parallel when safe, and integrate their results.
The coordination is simple: clear responsibilities, isolated work, and a final review.

!!! abstract "The core idea"
    **One agent per responsibility.** Keep agents focused. Let them run in parallel when they touch
    different files. Review and integrate in a final session.

## When to use multiple agents

| Scenario | What to do |
|---|---|
| Build and then optimize | Agent A writes correct code and tests. Agent B profiles and speeds it up. |
| Implement and review | Agent A writes the feature. Agent B reviews it in a fresh session and finds defects. |
| Many independent tasks | Agent A writes the CLI. Agent B builds the web app. Agent C writes tests. Run all in parallel. |
| Large refactor | Agent A refactors one module. Agent B refactors another. Merge and test together. |

Do *not* run agents in parallel if they edit the same files or test suite — the last write wins and earlier
work is lost.

## The parallel workflow

### 1. Plan once, divide the work

Write a single `AGENTS.md` that all agents will see. It states the goal, constraints, and acceptance tests.

```markdown
# Point Group Classifier

## Goal

Read an XYZ file and return the Schoenflies point group symbol.

## Acceptance

- All fixtures in `core_xyz/` pass (H₂ to B₁₂H₁₂ to cubane).
- No hard-coded formulas or filenames.
- Roundtrip test: rotated and permuted atoms give the same group.

## Assignment

- Agent A: Implement core symmetry detection.
- Agent B: Add CLI and I/O validation.
- Agent C: Profile and optimize hot paths.
```

### 2. Start independent sessions

Each session works in isolation. Give each session an ID so you can list and resume them later.

```bash
# Terminal 1: Core logic
opencode --session agent-core
# > Implement symmetry detection. Run tests from core_xyz/.

# Terminal 2: CLI and I/O
opencode --session agent-cli
# > Build a CLI that reads XYZ, calls the core module, returns the point group.

# Terminal 3: Optimization
opencode --session agent-optimize
# > Profile the core module. Speed up the slowest part. Keep tests green.
```

All three sessions read the same `AGENTS.md`, so they follow the same rules and commit to the same repository
(or worktrees; see below). Pause one session, resume another, and come back later.

### 3. Monitor progress

List your sessions anytime:

```bash
opencode session list
```

Resume a session by name:

```bash
opencode --session agent-core
```

### 4. Merge and verify

When all agents have finished, run a final session to merge branches, run the full test suite, and verify
acceptance criteria:

```bash
opencode --session final-integration
# > Merge branches from agent-core, agent-cli, and agent-optimize.
#   Run all tests in core_xyz/. If any fail, fix them and commit.
```

## Safe parallel work: Git worktrees

If agents make overlapping edits, use Git worktrees to give each agent its own checkout:

```bash
git worktree add ../work-core feature/core
git worktree add ../work-cli feature/cli
git worktree add ../work-optimize feature/optimize
```

In each directory, start a session:

```bash
cd ../work-core && opencode --session agent-core
cd ../work-cli && opencode --session agent-cli
cd ../work-optimize && opencode --session agent-optimize
```

Each worktree is on its own branch. When all are done:

```bash
# Back in the main worktree
git merge feature/core feature/cli feature/optimize
git worktree remove ../work-core ../work-cli ../work-optimize
```

## Tracing and reproducibility

Three mechanisms record what each agent did.

### Runtime logs (for troubleshooting)

Enable debug output to see tool calls, provider responses, and session activity:

```bash
opencode --print-logs --log-level DEBUG
```

Output goes to stderr. Log files are also saved to `~/.local/share/opencode/log/`. Use this when an agent
behaves unexpectedly or you need to see exact API requests and responses.

### Session export (for the record)

At any time, export a session to JSON:

```bash
opencode export agent-core > traces/agent-core.json
```

The JSON file contains every prompt, response, tool call, and result. It is a durable, machine-readable
transcript. Use it to review decisions, audit for compliance, or replay the session later.

### Project trace instructions (for coordination)

Define what each agent must record in a project Markdown file and load it from
`opencode.json`. The [chemistry example](agent-tracing.md) uses `docs/agent-tracing.md`;
any path works.

```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": [
    "AGENTS.md",
    "docs/agent-tracing.md"
  ]
}
```

## Example: Point group classifier with three agents

```bash
# Start three terminals.

# Terminal 1: Core logic
opencode --session agent-core
# > Implement symmetry detection. Run tests from core_xyz/. Commit after every green step.

# Terminal 2: CLI and I/O
opencode --session agent-cli
# > Build a CLI that calls the core module. All core_xyz/ tests still pass.

# Terminal 3: Optimization
opencode --session agent-optimize
# > Profile the core module. Find the slowest function and speed it up. Keep tests green.

# When all agents have committed and pushed:
opencode --session final-integration
# > Merge feature branches. Run the full test suite. All acceptance criteria met?
```

Review the traces:

```bash
opencode export agent-core > traces/agent-core.json
opencode export agent-cli > traces/agent-cli.json
opencode export agent-optimize > traces/agent-optimize.json
git log --oneline -20
```

## Safeguards

- **Secrets.** Do not log API keys, credentials, or PII. Redact exported traces before committing or sharing.
- **Review before merge.** Check each agent's commits and session export before merging branches.
- **Tests are the gate.** If the final test suite does not pass, review the agent's decisions and failures.
- **Separate concerns.** Keep agents focused on one task. If an agent is asked to do three things, it is three agents.
- **Commit often.** One feature per session; if it fails, revert and try again with better context.

## Debugging when agents disagree

If two agents produce conflicting code or a merge fails:

1. Export both sessions:
   ```bash
   opencode export agent-a > traces/agent-a.json
   opencode export agent-b > traces/agent-b.json
   ```

2. Review the logs. Look at the prompt each agent received and the first failure.

3. Start a fresh session to decide:
   ```bash
   opencode --session arbiter
   ```
   Show the arbiter both outputs, the test failures, and ask it to pick or merge the best parts.

4. Record the decision. Commit with a clear message about why you chose one approach.

## Where to go next

- [Best practices](best-practices.md): the six habits that work with any agent.
- [Tools cheat sheet](tools.md): the same moves in Claude Code, Codex, or Cursor.
- [Agent tracing](agent-tracing.md): a chemistry worked example of session records.
- [Hands-on lab](lab.md): the point-group classifier with demo repositories.
