# Agent tracing: a chemistry example

This page is a worked example for the [point-group classifier](lab.md). The fields and
workflow apply to any project; the molecule, XYZ fixtures and `detect_pointgroup` API
are chemistry-specific. Copy the pattern, not the filenames.

Load a tracing file like this one from `opencode.json` so every session sees the same
rules:

```json
{
  "instructions": ["AGENTS.md", "docs/agent-tracing.md"]
}
```

Replace `docs/agent-tracing.md` with your own file if your project is not chemistry.

## How to trace your work

### In commit messages

Every commit should have a clear subject and a body with trace fields:

```
Core symmetry detection

Session-ID: agent-core
Task: Implement point group detection for molecules.
Files-Changed: src/pointgroup/core.py, tests/test_core.py
Tests-Run: 24 core_xyz fixtures; all pass.
Key-Decision: Used 3D moment tensor for rotation-invariant comparison.
Alternative-Considered: Pairwise distances failed on rotated molecules.
Tests-Added: Roundtrip test (rotated = same group).
Blockers: None.
Handoff-Notes: Core module stable. CLI can call core.detect(xyz_path).
```

You do not need every field on every commit; use the ones relevant to that change.
`Session-ID` is a short name you choose for the agent's role (`agent-core`), not OpenCode's own
`ses_…` session ID; record that ID in the session summary so the export can be found later.

### In session summary

When done, add a summary to `traces/<session-id>.md` and commit it:

```markdown
# Agent Core Session Summary

**Session ID**: agent-core
**OpenCode session**: ses_3f2a...
**Role**: Implement core symmetry detection
**Start**: 2024-01-15 10:00 UTC
**End**: 2024-01-15 12:30 UTC

## What I did

- Implemented `detect_pointgroup(xyz_path: str) -> str` in `src/pointgroup/core.py`.
- Added 24 acceptance tests from `core_xyz/` fixtures.
- Added a roundtrip test to catch regressions.

## Test results

- Passed: all 24 `core_xyz` fixtures (H₂, H₂O, NH₃, CO₂, B₁₂H₁₂, cubane).
- Coverage: 94% of symmetry detection code.

## Key decisions

- Rotation-invariant representation: inertia-tensor eigenvalues, not pairwise distances.
- Symmetry operators: brute-force search of point-group tables (correct first; optimize later).

## Known issues

- None. All tests pass.
- Later: cache inertia-tensor eigenvalues for repeated calls.

## Handoff

Public API: `detect_pointgroup("molecule.xyz")` returns e.g. `C2v`.
Next agent: write the CLI wrapper and add file validation.

## Reproduce

uv run pytest tests/test_core.py -v
```

### In session export

Before handing off, export your session by its OpenCode ID (from `opencode session list`; in
OpenCode 2.x the command is `opencode session export`):

```bash
opencode export ses_3f2a... > traces/agent-core.json
```

The JSON contains every prompt, response, and tool call — the ground truth. For the same reason it can
contain anything listed under "Do not record" below, so keep exports out of Git by default
(`traces/*.json` in `.gitignore`) and share a redacted copy (`opencode export --sanitize`).

## What to include in traces

**Record:**

- Session ID and role.
- Task description.
- Files modified.
- Tests run and results.
- Key decisions and alternatives.
- Tests you added.
- Blockers or unresolved issues.
- Handoff notes for the next agent.

**Do not record:**

- API keys, credentials, or personal tokens.
- Passwords, passphrases, or authentication headers.
- Private data, proprietary information, or confidential research details.
- Full prompts containing sensitive scientific data.
- Model responses with PII or security-sensitive details.

Redact secrets from traces before committing or sharing. Commit the summaries and commit messages;
keep the raw session exports local unless you have reviewed them.

## Example: Full trace for a feature

```
commit a1b2c3d
Author: agent-core
Date:   Mon Jan 15 12:30 UTC 2024

    Implement symmetry detection for point groups

    Session-ID: agent-core
    Task: Implement detect_pointgroup(xyz_path) -> str.
    Files-Changed: src/pointgroup/core.py, tests/test_core.py
    Tests-Run: 24 core_xyz fixtures; all pass.
    Key-Decision: Inertia tensor eigenvalues for rotation-invariant representation.
    Tests-Added: Roundtrip test (rotate molecule, same group returned).
    Blockers: None.
    Handoff-Notes: Module ready for CLI wrapping. Public API in docstring.

commit 9f8e7d6
Author: agent-core
Date:   Mon Jan 15 10:05 UTC 2024

    Add roundtrip test for rotated molecules

    Session-ID: agent-core
    Task: Verify rotated molecules are classified the same.
    Files-Changed: tests/test_core.py
    Tests-Run: 1 new test, 23 existing. All pass.

commit 5e4d3c2
Author: agent-core
Date:   Mon Jan 15 10:02 UTC 2024

    Draft symmetry detection core

    Session-ID: agent-core
    Task: Scaffold the core detection function.
    Files-Changed: src/pointgroup/core.py, tests/test_core.py
    Tests-Run: 3 fixtures pass (H2, H2O, NH3).
    Tests-Added: Basic tests for three molecules.
    Blockers: Inertia tensor eigenvalues not yet computed.
    Handoff-Notes: Next: implement the tensor calculation.
```

## Using traces as a team

When the next agent starts:

1. Read the previous agent's session summary (`traces/agent-core.md`).
2. Check the git log to see commits and trace annotations.
3. Review the exported session if needed, one line per message:
   ```bash
   jq -r '.messages[] | "\(.info.role): \([.parts[] | select(.type == "text") | .text] | join(" "))"' \
     traces/agent-core.json | head -50
   ```

If something is unclear, ask the agent to clarify or start a new session with an arbiter to resolve.

## Integration session: assembling multiple agents' work

When all parallel agents are done:

```bash
opencode    # a fresh session in the main checkout
```

This session should:

1. Merge branches or worktrees.
2. Run the full test suite.
3. Verify that all acceptance criteria from `AGENTS.md` are met.
4. Commit with a summary trace:

```
Final integration and acceptance

Session-ID: final-integration
Sources: Merged feature/core, feature/cli, feature/optimize.
All-Tests: 24 core_xyz + 18 CLI + 12 performance benchmarks. All pass.
Acceptance: all AGENTS.md criteria met.
Performance: 50% speedup vs. initial implementation.
Handoff-Notes: Ready for code review and merge to main.
```

## Reference: Trace fields

| Field | Example | Use |
|---|---|---|
| **Session-ID** | `agent-core` | Which session? |
| **Task** | `Implement point group detection` | What were you asked to do? |
| **Files-Changed** | `src/core.py, tests/test.py` | Which files changed? |
| **Tests-Run** | `24 fixtures; all pass` | Did it work? |
| **Key-Decision** | `Inertia tensor for rotation invariance` | Why this choice? |
| **Alternative-Considered** | `Pairwise distances (rejected)` | What else did you try? |
| **Tests-Added** | `Roundtrip rotation test` | How to verify later? |
| **Blockers** | `None` or `Needs model update` | What is stuck? |
| **Handoff-Notes** | `Module ready for CLI wrapping` | What should next agent know? |

## Audit and reproducibility

Summaries and commit trailers are version-controlled in Git; session exports stay next to them,
outside Git, until reviewed:

```bash
# List all summaries and exports
ls traces/

# View any agent's summary
cat traces/agent-core.md

# List the messages of an exported session
jq '[.messages[] | {role: .info.role, parts: [.parts[].type]}]' traces/agent-core.json | head -50

# Commits made by one agent, with their trace fields
git log --grep='^Session-ID: agent-core$' --format='%h %s%n%b'
```

This creates a paper trail of decisions, helping with code review, debugging, and learning.
