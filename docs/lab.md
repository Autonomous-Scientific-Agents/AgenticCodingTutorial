# Hands-on lab: the point-group classifier

Build a Python package that reads a molecule's XYZ file and returns its Schoenflies point group
(`H2O_C2v.xyz` → `C2v`). The specification is a single `AGENTS.md`; the acceptance tests are the XYZ files in
`core_xyz/`, from H₂ to ferrocene, B₁₂H₁₂ (Ih) and cubane (Oh). The package must get every one right using only
the coordinates, without hard-coding filenames or formulas.

## Demo repositories

| Repository | What it is |
|---|---|
| [keceli/claude-pgmol](https://github.com/keceli/claude-pgmol) | **Start here.** `main` holds only the specification (`AGENTS.md`) and the `core_xyz/` fixtures. The branch [`feat/point-group-detection`](https://github.com/keceli/claude-pgmol/tree/feat/point-group-detection) is the package Claude Code built from it, with independent-review fixes and a harder `challenge_xyz/` set. |
| [Autonomous-Scientific-Agents/PGMol](https://github.com/Autonomous-Scientific-Agents/PGMol) | A finished implementation from the same specification: `pgmol` package, CLI, tests and CI. Compare it with yours. |

## Steps

```bash
git clone https://github.com/keceli/claude-pgmol.git
cd claude-pgmol
/path/to/run.sh            # optional: work inside the tutorial container
claude                     # or codex, opencode
```

| Step | You do | Checkpoint |
|---|---|---|
| 1 | Read `AGENTS.md` yourself first. What is the goal, what are the limits, how is success checked? | you can state the success criterion |
| 2 | Ask the agent for a plan before any code. Approve or correct it. | a plan you agree with |
| 3 | Let it build, one step per prompt. Read every diff; commit each green step. | all `core_xyz/` fixtures pass |
| 4 | Verify the verifier: try rotated and shuffled copies of a molecule, and a few `challenge_xyz/` files from the branch. | failures you understand |
| 5 | Review with a second tool or model; ask it to find defects, then fix them with tests. | review findings fixed |
| 6 | Stretch: profile on a large molecule and speed it up, or add a small GUI, keeping the tests green. | before/after numbers, or an app |

Compare your result with the `feat/point-group-detection` branch and with PGMol: same specification, different
code.
