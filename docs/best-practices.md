# Best practices

## The four steering layers

| Layer | What it holds | When it is loaded |
|---|---|---|
| **Instructions** (`AGENTS.md`, `CLAUDE.md`) | commands, conventions, rules that are always true ("tests are read-only") | every session |
| **Skills** (`SKILL.md`) | a procedure for one kind of task | name and description always; the body only when the task matches |
| **Memory** | facts carried across sessions | at session start |
| **Permissions** | what the agent may do without asking, and what it may never do | enforced by the tool, not read by the model |

Instructions file = always true. Skill = true when doing X. If a paragraph in your instructions file starts
with "when you …", it is a skill.

What is written on disk survives a long session; what you only said in the chat gets summarized and may be
lost. Put rules that must hold into the instructions file.

## Six habits that work in every agent

1. **Small steps, commit often.** One feature per prompt; run the tests after every change; commit after every success. git is the undo that works in every tool.
2. **Plan first, then build.** Anything touching several files: read-only plan mode, approve the plan, then switch to execute.
3. **One task per session.** /clear or /new between tasks. /compact with an instruction: “keep the failing test names”.
4. **Point, don't paste.** @src/pointgroup/core.py attaches the file; !uv run pytest -x puts the exact error in context. Pasted code goes stale.
5. **Cross-review with a second tool.** Implement in one agent, review in another. The shared AGENTS.md means both know the rules.
6. **Restart, don't argue.** If the agent spirals, stop. Restate the goal with better context, or start a fresh session — do not pile on corrections.

## Tests are the contract

- Write or obtain the tests first. The agent iterates until they pass.
- The agent must not edit the tests. If it thinks a test is wrong, it should say so and stop.
- Verify your verifier: cross-check expected values against an independent code before the agent trusts them.
- Write tests for failure paths and edge cases, not only for the correct answers.

## With great power comes great responsibility

Code is now cheap to write; reviewing, maintaining and trusting it are not. The trap is a pile of plausible
one-off scripts, duplicated helpers and untested variants. Spend the speed on what used to be too expensive:

| Push for better | What to ask the agent for |
|---|---|
| Correctness | edge-case and failure-path tests, property tests, a cross-check against an independent code |
| Performance | profile first, then vectorize, parallelize, port to GPU — with before/after numbers |
| Usability | a CLI or GUI, examples, a README a collaborator can follow |
| Maintainability | types, docstrings with units, a formatter and linter, no duplicated or dead code |

You are responsible for every line you merge, whoever typed it.

## Evidence

A December 2025 study by CodeRabbit (a vendor of AI code review) compared 320 open-source pull requests marked
as AI co-authored with 150 assumed to be human-only. The AI co-authored ones drew about 1.7 times as many review
findings, with the largest gaps in logic errors, error handling, readability and excessive I/O. Every one of
those categories has a countermeasure above. Read the
[report](https://www.coderabbit.ai/whitepapers/state-of-AI-vs-human-code-generation-report) and its limitations.
