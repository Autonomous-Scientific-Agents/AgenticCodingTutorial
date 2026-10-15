# Working with multiple agents

Divide a large task across several agents, run them in parallel when safe, and integrate their results.
The coordination is simple: clear responsibilities, isolated work, and a final review.

!!! abstract "The core idea"
    **One agent per responsibility, one checkout per agent.** Keep agents focused. Give each one its own Git
    worktree so they cannot overwrite each other. Review and integrate in a final session.

## When to use multiple agents

| Scenario | What to do |
|---|---|
| Build and then optimize | Agent A writes correct code and tests. Agent B profiles and speeds it up. |
| Implement and review | Agent A writes the feature. Agent B reviews it in a fresh session and finds defects. |
| Many independent tasks | Agent A writes the CLI. Agent B builds the web app. Agent C writes tests. Run all in parallel. |
| Large refactor | Agent A refactors one module. Agent B refactors another. Merge and test together. |

Do *not* let parallel agents share one checkout. They overwrite each other's edits, run each other's
half-finished tests, and commit each other's changes. Give each agent its own worktree (step 2).

The examples use OpenCode 1.x, the version in the [tutorial container](container.md). In OpenCode 2.x,
`opencode export` becomes `opencode session export`. Claude Code can do steps 2 and 3 in one command:
`claude -w core -n agent-core` creates a worktree and names the session.

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

Commit `AGENTS.md` before you create the worktrees, so every branch starts with it.

### 2. Give each agent its own worktree

A worktree is a second checkout of the same repository, on its own branch. Create one per agent:

```bash
git worktree add -b feature/core ../work-core
git worktree add -b feature/cli ../work-cli
git worktree add -b feature/optimize ../work-optimize
```

### 3. Start one session per worktree

```bash
# Terminal 1: Core logic
cd ../work-core && opencode
# > Implement symmetry detection. Run tests from core_xyz/. Commit after every green step.

# Terminal 2: CLI and I/O
cd ../work-cli && opencode
# > Build a CLI that reads XYZ, calls the core module, returns the point group.

# Terminal 3: Optimization
cd ../work-optimize && opencode
# > Profile the core module. Speed up the slowest part. Keep tests green.
```

All three sessions read the same `AGENTS.md`, so they follow the same rules, and each commits to its own
branch.

### 4. Monitor and resume

OpenCode gives each session an ID such as `ses_3f2a…`; you cannot choose it. List sessions with their IDs and
titles:

```bash
opencode session list
```

Resume one by ID:

```bash
cd ../work-core && opencode --session ses_3f2a...
```

Note each agent's ID; you need it to export the session later.

### 5. Merge and verify

When all agents have finished, merge the branches one at a time from the main checkout, so a conflict stops
you at the branch that caused it:

```bash
git merge feature/core
git merge feature/cli
git merge feature/optimize
```

Then start a fresh session there to run the full test suite and check the acceptance criteria:

```bash
opencode
# > Run all tests in core_xyz/. Check every acceptance criterion in AGENTS.md. Fix failures and commit.
```

Remove the worktrees once the branches are merged (one path per command):

```bash
git worktree remove ../work-core
git worktree remove ../work-cli
git worktree remove ../work-optimize
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

At any time, export a session to JSON by its ID:

```bash
mkdir -p traces
opencode export ses_3f2a... > traces/agent-core.json
```

The JSON file contains every prompt, response, tool call, and result. It is a durable, machine-readable
transcript. Use it to review decisions, audit for compliance, or replay the session later.

Because it contains everything, including any secret or unpublished data that passed through the session,
keep exports out of Git by default (add `traces/*.json` to `.gitignore`). `opencode export --sanitize`
writes a redacted copy for sharing.

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

## Safeguards

- **Secrets.** Do not log API keys, credentials, or PII. Redact exported traces before committing or sharing.
- **Review before merge.** Check each agent's commits and session export before merging branches.
- **Tests are the gate.** If the final test suite does not pass, review the agent's decisions and failures.
- **Separate concerns.** Keep agents focused on one task. If an agent is asked to do three things, it is three agents.
- **Commit often.** One feature per session; if it fails, revert and try again with better context.

## Debugging when agents disagree

If two agents produce conflicting code or a merge fails:

1. Export both sessions (IDs from `opencode session list`):
   ```bash
   opencode export ses_aaaa... > traces/agent-a.json
   opencode export ses_bbbb... > traces/agent-b.json
   ```

2. Review the logs. Look at the prompt each agent received and the first failure.

3. Start a fresh session to decide:
   ```bash
   opencode
   ```
   Show this arbiter both outputs and the test failures, and ask it to pick or merge the best parts.

4. Record the decision. Commit with a clear message about why you chose one approach.

## Where to go next

- [Best practices](best-practices.md): the six habits that work with any agent.
- [Tools cheat sheet](tools.md): the same moves in Claude Code, Codex, and OpenCode.
- [Agent tracing](agent-tracing.md): a chemistry worked example of session records.
- [Hands-on lab](lab.md): the point-group classifier with demo repositories.
