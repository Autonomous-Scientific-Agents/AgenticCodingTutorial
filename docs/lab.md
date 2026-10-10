# Hands-on lab: the point-group classifier

Classify the point group of a molecule from its Cartesian coordinates. The repository starts with a stub and
94 tests (91 failing): 60 molecules across 40 point groups plus challenge cases — random orientations, permuted
atoms, H vs D isotopes, noise, and tolerance edge cases. Every expected label was cross-checked against pymatgen.

!!! note
    The link to the lab repository will be posted here before the session.

| Step | You do | Checkpoint | min |
|---|---|---|---|
| 0 | git clone …/pointgroup; git checkout v0-spec; uv sync; uv run pytest → 91 failures. Pick Claude Code, OpenCode or Codex (or Cursor / Kilo Code). | agent explains the failing tests | 5 |
| 1 | Build with tests: one prompt; do not help; watch the loop. Reject one questionable change in the diff. | pytest green; commit | 20 |
| 2 | Instructions: /init (or equivalent), cut to < 60 lines, add “run pytest before done”. | fewer exploratory tool calls on a re-run | 10 |
| 3 | Make it fast: ask for a profile on bench/, then one optimisation. Tests must stay green. Write a benchmark skill. | ≥ 5× on the batch benchmark | 15 |
| 4 | Give it a face: one prompt for a Streamlit app; approve or deny install/port requests deliberately. | app runs locally | 15 |
| 5 | Memory & stretch: audit auto-memory, promote one fact; open the repo in a second tool; add a hook that blocks writes outside the repo. | second tool reads AGENTS.md | 10 |

Stuck? Check out the next tag (`v1-passing`, `v2-fast`, `v3-gui`) and carry on.

```bash
uv sync
uv run pytest        # the tests are the contract: do not edit tests/
```
